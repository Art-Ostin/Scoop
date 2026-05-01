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
    var invites: [EventProfile] = []
    var events: [EventProfile] = []
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
//        chatsStream()
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
}


//Events Stream
extension SessionManager {
    
    private func recentChatStream() {
        let stream = eventsRepo.eventMessageTracker(userId: user.id)

        streams.insert("recentChat", Task { @MainActor in
            do {
                for try await change in stream {
                    switch change {
                    case .initial: continue
                    case .added(let popup): presentPopup(popup)
                    case .modified(let popup): presentPopup(popup)
                    case .removed: continue
                    }
                }
            } catch {
                print(error)
            }
        })
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

    private func eventsStream() {
        let stream = eventsRepo.eventTracker(userId: user.id)

        streams.insert("events", Task { @MainActor in
            do {
                for try await change in stream {
                    switch change {
                    case .initial(let events): try await loadEvents(events: events)
                    case .added(let event): try await addProfile(event: event)
                    case .modified(let event): updateModifiedProfile(event: event)
                    case .removed(let id): _ = removeAndReturnProfile(id: id)
                    }
                }
            } catch {
                print(error)
            }
        })
    }
    
    private func loadEvents(events: [UserEvent]) async throws {
        let b = profileLoader
        
        let invites = events.filter {$0.status == .pending && $0.role == .received }
        let accepted = events.filter {$0.status == .accepted}
        let pastAccepted = events.filter {$0.status == .pastAccepted}
        
        async let inv  = b.fromEvents(invites)
        async let acc  = b.fromEvents(accepted)
        async let past = b.fromEvents(pastAccepted)
        
        (self.invites, self.events, self.pastEvents) = try await(inv, acc, past)
    }
    
    private func addProfile(event: UserEvent) async throws {
        if event.status == .pending && event.role == .received {
            let profile = try await profileLoader.fromEvents([event])
            self.invites.append(contentsOf: profile)
        }
    }
    
    private func updateModifiedProfile(event: UserEvent) {
        //If it is in invites, and its status is no long invites, add it to accepted
        if event.status == .accepted, invites.contains(where: { $0.id == event.id }), let profile = removeAndReturnProfile(id: event.id) {
            events.append(profile)
            
        //If it is in events, and its status is no long events, add it to pastAccepted
        } else if event.status == .pastAccepted, events.contains(where: { $0.id == event.id }), let profile = removeAndReturnProfile(id: event.id) {
            pastEvents.append(profile)
        }
    }
    
    private func removeAndReturnProfile(id: String) -> EventProfile? {
        let localProfile =
        invites.first(where: { $0.event.id == id }) ??
        events.first(where: { $0.event.id == id }) ??
        pastEvents.first(where: { $0.event.id == id })
        
        invites.removeAll { $0.event.id == id }
        events.removeAll { $0.event.id == id }
        pastEvents.removeAll { $0.event.id == id }
        
        return localProfile
    }
}

extension SessionManager {
    

    private func profilesStream() {
        let stream = profilesRepo.profilesTracker(userId: user.id)

        streams.insert("profiles", Task { @MainActor in
            do {
                for try await change in stream {
                    switch change {
                    case .initial(let profileRecs):
                        let profileIds = profileRecs.compactMap {$0.id}
                        let profiles = try await profileLoader.fromIds(profileIds)
                        self.profiles = profiles
                    case .added(let profileRec):
                        if let id = profileRec.id {
                            let profile = try await profileLoader.fromIds([id])
                            self.profiles.append(contentsOf: profile)
                        }
                    case .modified:
                        break
                        //Don't need to do anything
                    case .removed(let id):
                        profiles.removeAll { $0.id == id }
                    }
                }
            } catch {
                print(error)
            }
        })
    }

    //Listen to user's profile in case there is an update on their account.
    private func userProfileStream() {
        streams.insert("userProfile", Task { @MainActor in
            do {
                for try await change in userRepo.userListener(userId: user.id) {
                    //1. If they have updated their profile/preference make the session user, reflect this change
                    if let change {
                        sessionUser = change

                        //2.If change is 'user's status' i.e. to blocked or frozen, update appState.
                        if let appStateBinding {
                            updateAppState(appStateBinding, for: change)
                        }
                    }
                }
            } catch {
                print(error)
            }
        })
    }
    
    //Checks if user is blocked or frozen before going to main appState
    private func updateAppState(_ appState: Binding<AppState>, for user: UserProfile) {
        if user.isBlocked || user.frozenUntil != nil {
            appState.wrappedValue = .frozen
        } else {
            appState.wrappedValue = .app
        }
    }
}




/*
 //    var chats: [ChatModel] = []

 
//    private func chatsStream() {
//        let stream = chatRepo.chatsTracker(userId: user.id)
//
//        streams.insert("chats", Task { @MainActor in
//            do {
//                for try await change in stream {
//                    switch change {
//                    case .initial(let chats):
//                        self.chats = chats
//                    case .added(let chat):
//                        chats.append(chat)
//                    case .modified(let chat):
//                        if let idx = self.chats.firstIndex(where: { $0.id == chat.id }) {
//                            self.chats[idx] = chat
//                        }
//                    case .removed(let id):
//                        self.chats.removeAll { $0.id == id }
//                    }
//                }
//            } catch {
//                print(error)
//            }
//        })
//    }
 */
