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
        async let eventsReady: Void = eventsStream()
        async let profilesReady: Void = startProfilesStream()
        _ = await (eventsReady, profilesReady)
        
        //3.
//        userProfileStream()
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
        if user.isBlocked || user.frozenUntil != nil {
            appState.wrappedValue = .frozen
        } else {
            appState.wrappedValue = .app
        }
    }
}


//Events Stream
extension SessionManager {
    
    private func eventsStream() {
        eventStreamTask?.cancel()
        let stream = eventsRepo.eventTracker(userId: user.id)

        eventStreamTask = Task { @MainActor in
            for try await change in stream {
                switch change {
                case .initial(let events): try await loadEvents(events: events)
                case .added(let item): try await addProfile(item: item)
                case .modified(let item): updateModifiedProfile(item: item)
                case .removed(let id): _ = removeAndReturnProfile(id: id)
                }
            }
        }
    }
    
    private func loadEvents(events: [FSCollectionItem<UserEvent>]) async throws {
        let events = events.map(\.model)
        let b = profileLoader
        
        let invites = events.filter {$0.status == .pending && $0.role == .received }
        let accepted = events.filter {$0.status == .accepted}
        let pastAccepted = events.filter {$0.status == .pastAccepted}
        
        async let inv  = b.fromEvents(invites)
        async let acc  = b.fromEvents(accepted)
        async let past = b.fromEvents(pastAccepted)

        (self.invites, self.events, self.pastEvents) = try await(inv, acc, past)
    }
    
    private func addProfile(item: FSCollectionItem<UserEvent>) async throws {
        let event = item.model
        if event.status == .pending && event.role == .received {
            let profile = try await profileLoader.fromEvents([event])
            self.invites.append(contentsOf: profile)
        }
    }
    
    private func updateModifiedProfile(item: FSCollectionItem<UserEvent>) {
        //Can only be updated to .accepted or .pastAccepted, .pending (Otherwise, its removed category)
        if let profile = removeAndReturnProfile(id: item.id), let event = profile.event {
            if event.status == .accepted {
                events.append(profile)
            } else if event.status == .pastAccepted {
                pastEvents.append(profile)
            }
        }
    }
    
    private func removeAndReturnProfile(id: String) -> ProfileModel? {
        let localProfile =
        invites.first(where: { $0.event?.id == id }) ??
        events.first(where: { $0.event?.id == id }) ??
        pastEvents.first(where: { $0.event?.id == id })
        
        invites.removeAll { $0.event?.id == id }
        events.removeAll { $0.event?.id == id }
        pastEvents.removeAll { $0.event?.id == id }
        
        return localProfile
    }
}

extension SessionManager {
    
    private func profilesStream() {
        
    }
}







//Store the three key streams here
extension SessionManager  {
    
    private func upsert(_ model: ProfileModel, into models: inout [ProfileModel]) {
        if let index = models.firstIndex(where: { $0.id == model.id }) {
            models[index] = model
        } else {
            models.append(model)
        }
    }

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
                                let model = try await profileLoader.fetchProfileModel(id, event: nil)
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
 
    
    
    
    
    
    
    
    
    
    
    

    
    //The user's profile listener. Changes in firebase instantly updates user
    func userProfileStream() {
        userProfileStreamTask?.cancel()
        userProfileStreamTask = Task { @MainActor in
            do {
                for try await change in userRepo.userListener(userId: user.id) {
                    if let change {
                        //If profile updated, this ensure 'sessionUser' instantly reflects changes
                        sessionUser = change
                        print("Updated")
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
