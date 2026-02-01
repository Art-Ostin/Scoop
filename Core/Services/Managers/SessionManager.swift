//
//  SessionManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import SwiftUI

enum showProfilesState {
    case active, closed, respond
}

@MainActor
@Observable class SessionManager {
    
    let authService: AuthServicing
    
    let userRepo: UserRepository
    let eventsRepo: EventsRepository
    let profilesRepo: ProfilesRepository
    
    let profileLoader: ProfileLoading
    let imageLoader: ImageLoading
    let defaultsManager: DefaultsManaging
    
    private(set) var session: Session?
    
    //Store the streams, so that if the session closes cancel all of them
    private var userStreamTask: Task<Void, Never>?
    private var profileStreamTask: Task<Void, Never>?
    private var eventStreamTask: Task<Void, Never>?
    private var userProfileStreamTask: Task<Void, Never>?
    
    private var appStateBinding: Binding<AppState>?
    
    var user: UserProfile {
        guard let session else { fatalError("Session not started") }
        return session.user
    }
        
    init(
        authService: AuthServicing,
        defaultsManager: DefaultsManaging,
        userRepo: UserRepository,
        eventsRepo: EventsRepository,
        profilesRepo: ProfilesRepository,
        profileLoader: ProfileLoading,
        imageLoader: ImageLoading)
    {
        self.authService = authService
        self.defaultsManager = defaultsManager
        self.userRepo = userRepo
        self.eventsRepo = eventsRepo
        self.profilesRepo = profilesRepo
        self.profileLoader = profileLoader
        self.imageLoader = imageLoader
    }
    
    //Tracks if user signed in or not & decides app state on launch
    func userStream (appState: Binding<AppState>) {
        userStreamTask = Task { @MainActor in
            
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
                    session = nil
                    continue
                }
                //3. Otherwise start session with the user inputted which triggers loading up
                await startSession(user: user) {
                    self.updateAppState(appState, for: user)
                }
                Task { await imageLoader.loadProfileImages([user]) }
            }
        }
    }

    func startSession(user: UserProfile, onReady: (() -> Void)? = nil) async {
        //1. Stop Previous session, and populate new with the user
        stopSession()
        self.session = Session(user: user)
        
        //2. Populate session fields and open up listener for events & profiles
        async let eventsReady: Void = startEventsStream()
        async let profilesReady: Void = startProfilesStream()
        _ = await (eventsReady, profilesReady)
        
        //3.
        userProfileStream()
        onReady?()
    }
        
    func stopSession() {
        profileStreamTask?.cancel()
        eventStreamTask?.cancel()
        userProfileStreamTask?.cancel()
        session = nil
    }
    
    //Checks if user is blocked or frozen before going to main appState
    private func updateAppState(_ appState: Binding<AppState>, for user: UserProfile) {
        if user.isBlocked {
            appState.wrappedValue = .blocked
        } else if user.frozenUntil != nil {
            appState.wrappedValue = .frozen
        } else {
            appState.wrappedValue = .app
        }
    }
}

//Store the three key streams here
extension SessionManager  {

    //Loads up all 'invites' from the profiles folder and begins the listener if any change
    private func startProfilesStream() async {
        profileStreamTask?.cancel()
        do {
            let (initial, updates) = try await profilesRepo.profilesListener(userId: user.id)
            let ids = initial.compactMap(\.id)
            session?.profiles = try await profileLoader.fromIds(ids)   // initial load done here
            profileStreamTask = Task { @MainActor in
                do {
                    for try await update in updates {
                        switch update {
                        case .addProfile(let id):
                            if !(session?.profiles.contains(where: { $0.id == id }) ?? false) {
                                let model = try await profileLoader.fromId(id)
                                session?.profiles.append(model)
                            }
                        case .removeProfile(let id):
                            session?.profiles.removeAll(where: { $0.id == id })
                        }
                    }
                } catch { print(error) }
            }
        } catch {
            print(error)
        }
    }
    
    //Loads up all users (1) events (2) past events and populates respective fields.
    private func startEventsStream(now: Date = .init()) async {
        eventStreamTask?.cancel()
        do {
            let (initial, updates) = try await eventsRepo.eventTracker(userId: user.id, now: now)
            let invites = initial.filter { $0.kind == .invite }.map(\.event)
            let accepted = initial.filter { $0.kind == .accepted }.map(\.event)
            let past = initial.filter { $0.kind == .pastAccepted }.map(\.event)
            let (invModels, accModels, pastModels) = try await buildEvents(profileLoader, invites: invites,accepted: accepted,past: past)

            session?.invites = invModels
            session?.events = accModels
            session?.pastEvents = pastModels   // <- also fixes your `session.pastEvents` bug
            eventStreamTask = Task { @MainActor in
                do {
                    for try await (event, kind) in updates {
                        switch kind {
                        case .invite:
                            if let model = try? await profileLoader.fromEvent(event),
                               !(session?.invites.contains(where: { $0.id == model.id }) ?? false) {
                                session?.invites.append(model)
                            }

                        case .accepted:
                            if let model = try? await profileLoader.fromEvent(event),
                               !(session?.events.contains(where: { $0.id == model.id }) ?? false) {
                                session?.events.append(model)
                            }

                        case .pastAccepted:
                            if let model = try? await profileLoader.fromEvent(event),
                               !(session?.pastEvents.contains(where: { $0.id == model.id }) ?? false) {
                                session?.pastEvents.append(model)
                            }

                        case .remove:
                            session?.invites.removeAll { $0.id == event.otherUserId }
                            session?.events.removeAll { $0.id == event.otherUserId }
                            session?.pastEvents.removeAll { $0.id == event.otherUserId }
                        }
                    }
                } catch { print(error) }
            }
        } catch {
            print(error)
        }
    }
    
    //Refreshes the app when user updates their profile (try deleting and test)
    func userProfileStream() {
        userProfileStreamTask?.cancel()
        userProfileStreamTask = Task { @MainActor in
            do {
                for try await change in userRepo.userListener(userId: user.id) {
                    if let change {
                        session?.user = change
                        if let appStateBinding {
                            updateAppState(appStateBinding, for: change)
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}

struct Session {
    var user: UserProfile
    var profiles: [ProfileModel] = []
    var invites: [ProfileModel] = []
    var events: [ProfileModel] = []
    var pastEvents: [ProfileModel] = []
}

//Important that this is done of the main Thread, so function not in session Manager
func buildEvents(_ b: ProfileLoading, invites: [UserEvent], accepted: [UserEvent], past: [UserEvent]) async throws -> ([ProfileModel],[ProfileModel],[ProfileModel]) {
    async let inv  = b.fromEvents(invites)
    async let acc  = b.fromEvents(accepted)
    async let past = b.fromEvents(past)
    return try await (inv, acc, past)
}
