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
    
    //Session starts with this variable assigned
    private var sessionUser: UserProfile?
    
    //Store the streams, so that if the session closes cancel all of them
    private var userStreamTask: Task<Void, Never>?
    private var profileStreamTask: Task<Void, Never>?
    private var eventStreamTask: Task<Void, Never>?
    private var userProfileStreamTask: Task<Void, Never>?
    
    private var appStateBinding: Binding<AppState>?
    
    //Key values need access to throughout App.
    var user: UserProfile {
        guard let sessionUser else { fatalError("Session not started") }
        return sessionUser
    }
    var profiles: [ProfileModel] = []
    var invites: [ProfileModel] = []
    var events: [ProfileModel] = []
    var pastEvents: [ProfileModel] = []
        
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
        appStateBinding = appState
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
                    sessionUser = nil
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
        sessionUser = user
        
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
        sessionUser = nil
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
            profiles = try await profileLoader.fromIds(ids)   // initial load done here
            profileStreamTask = Task { @MainActor in
                do {
                    for try await update in updates {
                        switch update {
                        case .addProfile(let id):
                            if !profiles.contains(where: { $0.id == id }) {
                                let model = try await profileLoader.fromId(id)
                                profiles.append(model)
                            }
                        case .removeProfile(let id):
                            profiles.removeAll(where: { $0.id == id })
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
            let invitesReceived = initial.filter { $0.kind == .invite }.map(\.event)
            let accepted = initial.filter { $0.kind == .accepted }.map(\.event)
            let past = initial.filter { $0.kind == .pastAccepted }.map(\.event)
            let (invModels, accModels, pastModels) = try await buildEvents(profileLoader, invites: invitesReceived, accepted: accepted,past: past)

            invites = invModels
            events = accModels
            pastEvents = pastModels   // <- also fixes your `session.pastEvents` bug
            eventStreamTask = Task { @MainActor in
                do {
                    for try await (event, kind) in updates {
                        switch kind {
                        case .invite:
                            if let model = try? await profileLoader.fromEvent(event),
                               invites.contains(where: { $0.id == model.id }) {
                                invites.append(model)
                            }

                        case .accepted:
                            if let model = try? await profileLoader.fromEvent(event),
                               events.contains(where: { $0.id == model.id }) {
                                events.append(model)
                            }

                        case .pastAccepted:
                            if let model = try? await profileLoader.fromEvent(event),
                               pastEvents.contains(where: { $0.id == model.id }) {
                                pastEvents.append(model)
                            }

                        case .remove:
                            invites.removeAll { $0.id == event.otherUserId }
                            events.removeAll { $0.id == event.otherUserId }
                            pastEvents.removeAll { $0.id == event.otherUserId }
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
                        sessionUser = change
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

//Important that this is done of the main Thread, so function not in session Manager
func buildEvents(_ b: ProfileLoading, invites: [UserEvent], accepted: [UserEvent], past: [UserEvent]) async throws -> ([ProfileModel],[ProfileModel],[ProfileModel]) {
    async let inv  = b.fromEvents(invites)
    async let acc  = b.fromEvents(accepted)
    async let past = b.fromEvents(past)
    return try await (inv, acc, past)
}
