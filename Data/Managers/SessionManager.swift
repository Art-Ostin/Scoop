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
    
    var profiles: [PendingProfile] = []
    var invites: [EventProfile] = []
    var events: [EventProfile] = []
    var pastEvents: [EventProfile] = []
    
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
                
        //3.Update the AppState and add profileImages
        if let appState {
            updateAppState(appState, for: user)
        }
        Task { await imageLoader.loadProfileImages(user) }
    }
    
    //Not private as need it when sign out
    func stopSession() {
        profileStreamTask?.cancel()
        eventStreamTask?.cancel()
        userProfileStreamTask?.cancel()
        sessionUser = nil
    }
}


//Events Stream
extension SessionManager {
    
    private func eventsStream() {
        eventStreamTask?.cancel()
        let stream = eventsRepo.eventTracker(userId: user.id)
        
        eventStreamTask = Task { @MainActor in
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
        }
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
        profileStreamTask?.cancel()
        let stream = profilesRepo.profilesTracker(userId: user.id)
        
        profileStreamTask = Task { @MainActor in
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
        }
    }
    
    //Listen to user's profile in case there is an update on their account.
    private func userProfileStream() {
        userProfileStreamTask?.cancel()
        userProfileStreamTask = Task { @MainActor in
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
        }
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
 Might need for profile ordering. Not sure yet
 private func upsert(_ model: EventProfile, into models: inout [ProfileModel]) {
     if let index = models.firstIndex(where: { $0.id == model.id }) {
         models[index] = model
     } else {
         models.append(model)
     }
 }

 */
