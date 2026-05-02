//
//  SessionManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import SwiftUI

enum ShowProfilesState {
    case active, closed, respond
}

@MainActor
//Creat a 'Task Bag' to hold all the stream Tasks. Then can cancel them later
final class TaskBag {
    private var tasks: [String: Task<Void, Never>] = [:]
    func insert(_ key: String, _ task: Task<Void, Never>) {
        tasks[key]?.cancel()
        tasks[key] = task
    }
    func cancel(_ key: String) {
        tasks.removeValue(forKey: key)?.cancel()
    }
    func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
}

@MainActor
@Observable class SessionManager {

    //Creates a Reusable Sequence throughout the session Manager
    private func subscribe<S: AsyncSequence>(
        _ key: String,
        to stream: S,
        handler: @escaping (S.Element) async throws -> Void
    ) {
        streams.insert(key, Task { @MainActor in
            do {
                for try await element in stream {
                    try await handler(element)
                }
            } catch {
                print(error)
            }
        })
    }
    
    let authService: AuthServicing

    let userRepo: UserRepository
    let eventsRepo: EventsRepository
    let profilesRepo: ProfilesRepository
    let chatRepo: ChatRepository

    let profileLoader: ProfileLoading
    let imageLoader: ImageLoading
    let defaultsManager: DefaultsManaging

    //Session starts with this variable assigned
    private var sessionUser: UserProfile?

    //Auth listener spans the app lifetime; session streams are cancelled together on sign-out.
    private var authStreamTask: Task<Void, Never>?
    private let streams = TaskBag()

    private var appStateBinding: Binding<AppState>?
    
    //Key values need access to throughout App.
    var user: UserProfile {
        guard let sessionUser else { fatalError("Session not started") }
        return sessionUser
    }
    
    private(set) var profiles: [PendingProfile] = []
    private(set) var invites: [EventProfile] = []
    private(set) var events: [EventProfile] = []
    private(set) var pastEvents: [EventProfile] = []
    
    var recentMessageReceived: MessagePopupModel?
    var activeChatEventId: String?
    
    init(
        authService: AuthServicing,
        defaultsManager: DefaultsManaging,
        userRepo: UserRepository,
        eventsRepo: EventsRepository,
        profilesRepo: ProfilesRepository,
        chatRepo: ChatRepository,
        profileLoader: ProfileLoading,
        imageLoader: ImageLoading)
    {
        self.authService = authService
        self.defaultsManager = defaultsManager
        self.userRepo = userRepo
        self.eventsRepo = eventsRepo
        self.profilesRepo = profilesRepo
        self.chatRepo = chatRepo
        self.profileLoader = profileLoader
        self.imageLoader = imageLoader
    }
}

//Logic dealing with what part of app to show to user and when, and User's Status
extension SessionManager {
    
    //Tracks if user signed in or not & decides app state on launch
    func userStream (appState: Binding<AppState>) {
        appStateBinding = appState
        authStreamTask?.cancel()
        authStreamTask = Task { @MainActor in
            
            for await uid in authService.authStateStream() {
                //1. If no authenticated user go to the login state
                guard let uid else {
                    stopSession()
                    appState.wrappedValue = .login
                    defaultsManager.deleteDefaults()
                    continue
                }
                //2. If no profile fetched go to the onboarding state
                guard let user = try? await userRepo.fetchProfile(userId: uid) else {
                    appState.wrappedValue = .createAccount
                    sessionUser = nil
                    continue
                }
                
                //3. Otherwise start session with the user inputted which triggers loading up
                startSession(user: user, appState: appState)
            }
        }
    }
    
    //Not private as need it to sign up
    func startSession(user: UserProfile, appState: Binding<AppState>? = nil) {
        //1. Start new session, inputting a user
        stopSession()
        sessionUser = user
        
        //2. Start the streams with initial snapshots
        eventsStream()
        profilesStream()
        userProfileStream()
        recentChatStream()

        //3.Update the AppState and add profileImages
        if let appState {
            updateAppState(appState, for: user)
        }
        Task { await imageLoader.loadProfileImages(user) }
    }
    
    //Not private as need it when sign out
    func stopSession() {
        streams.cancelAll()
        recentMessageReceived = nil
        activeChatEventId = nil
        sessionUser = nil
    }
    
    //Checks if user is blocked or frozen before going to main appState
    private func updateAppState(_ appState: Binding<AppState>, for user: UserProfile) {
        if user.isBlocked || user.frozenUntil != nil {
            appState.wrappedValue = .frozen
        } else {
            appState.wrappedValue = .app
        }
    }
    
    //Listen to user's profile in case there is an update on their account, and updates the User
    private func userProfileStream() {
        subscribe("userProfile", to: userRepo.userListener(userId: user.id)) { [weak self] change in
            guard let self, let change else { return }
            self.sessionUser = change
            if let binding = self.appStateBinding {
                self.updateAppState(binding, for: change)
            }
        }
    }
}

//Logic dealing with the User's Events
extension SessionManager {
    
    //1. Listens to all user events where status is pending, accepted, or past accepted
    private func eventsStream() {
        subscribe("events", to: eventsRepo.eventTracker(userId: user.id)) { [weak self] change in
            guard let self else { return }
            switch change {
            case .initial(let events):  try await self.loadInitialEvents(events: events)
            case .added(let event):     try await self.addProfileToInvites(event: event)
            case .modified(let event):  self.updateModifiedProfile(event: event)
            case .removed(let id):      self.removeProfile(id: id)
            }
        }
    }

    //2. On initial launch populates all the users invites, events, and past events for session
    private func loadInitialEvents(events: [UserEvent]) async throws {
        let invites = events.filter {$0.status == .pending && $0.role == .received }
        let accepted = events.filter {$0.status == .accepted}
        let pastAccepted = events.filter {$0.status == .pastAccepted}
        
        async let inv  = profileLoader.fromEvents(invites)
        async let acc  = profileLoader.fromEvents(accepted)
        async let past = profileLoader.fromEvents(pastAccepted)
        
        (self.invites, self.events, self.pastEvents) = try await(inv, acc, past)
    }
    
    //3. If new event added, if its user who received event, add it to invites
    private func addProfileToInvites(event: UserEvent) async throws {
        guard event.status == .pending, event.role == .received else { return }
        let profile = try await profileLoader.fromEvents([event])
        invites.append(contentsOf: profile)
    }
    
    //4. Function called if event modified at all. When user accepts invite when session active, this is triggered
    private func updateModifiedProfile(event: UserEvent) {
        switch event.status {
        case .accepted:
            if let i = invites.firstIndex(where: { $0.event.id == event.id }) {
                events.append(invites.remove(at: i))
            }
        case .pastAccepted:
            if let i = events.firstIndex(where: { $0.event.id == event.id }) {
                pastEvents.append(events.remove(at: i))
            }
        default:
            break
        }
    }
    
    //5. Function called to remove profile
    private func removeProfile(id: String) {
        invites.removeAll { $0.event.id == id }
        events.removeAll { $0.event.id == id }
        pastEvents.removeAll { $0.event.id == id }
    }
    
    //Want to remove these profiles
    //6. For local Session if accepted add it to acepted events (If listener set up right, could delete)
    func updateAcceptedEventInSession(eventProfile: EventProfile) {
        events.append(eventProfile)
    }
    
    //7.For local session if responded with new time, event, or declined remove it from invites (can also remove if listener works nicely)
    func removeInvitedEventInSession(id: String) {
        invites.removeAll { $0.id == id }
    }
}

//Logic dealing with the recommended Profiles shown to the User
extension SessionManager {
    
    private func profilesStream() {
        subscribe("profiles", to: profilesRepo.profilesTracker(userId: user.id)) { [weak self] change in
            guard let self else { return }
            switch change {
            case .initial(let recs):
                self.profiles = try await self.profileLoader.fromIds(recs.compactMap { $0.id })
                print("profiles Loaded")
            case .added(let rec):
                if let id = rec.id {
                    self.profiles.append(contentsOf: try await self.profileLoader.fromIds([id]))
                }
            case .modified:
                break
            case .removed(let id):
                self.profiles.removeAll { $0.id == id }
            }
        }
    }
}

//Logic dealing with the popups in the app shown to the User
extension SessionManager {
    
    private func recentChatStream() {
        subscribe("recentChat", to: eventsRepo.eventMessageTracker(userId: user.id)) { [weak self] change in
            switch change {
            case .added(let popup), .modified(let popup):
                self?.presentPopup(popup)
            case .initial, .removed:
                break
            }
        }
    }

    private func presentPopup(_ popup: MessagePopupModel) {
        guard popup.eventId != activeChatEventId else { return }
        recentMessageReceived = popup
        streams.insert("dismissPopup", Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.recentMessageReceived = nil
        })
    }
    
}





