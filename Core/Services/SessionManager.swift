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
    
    
    private let authService: AuthManaging
    
    
    
    private let eventRepo: EventManager
    private let imageLoader: CacheManaging
    private let userManager: UserManager
    private let defaultManager: DefaultsManager
    private let profileBuilder: ProfileModelBuilder
    
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
    var profiles: [ProfileModel] = []
    var invites: [ProfileModel] = []
    var events: [ProfileModel] = []
    var pastEvents: [ProfileModel] = []
    
    init(eventManager: EventManager, cacheManager: CacheManaging, userManager: UserManager, authManager: AuthManaging, defaultManager: DefaultsManager) {
        self.eventManager = eventManager
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.authManager = authManager
        self.defaultManager = defaultManager
        self.profileBuilder = ProfileModelBuilder(userManager: userManager, cache: cacheManager)
    }
    
    func startSession(user: UserProfile, onReady: (() -> Void)? = nil) async {
        stopSession() ;
        session = Session(user: user)
        
        async let eventsLoaded: Void = withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            Task { await userEventsStream { cont.resume() } }
        }

        async let profilesLoaded: Void = {
            if let id = await loadCycle(userId: user.id) {
                return await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                    Task { await profilesStream(cycleId: id) { cont.resume() } }
                }
            } else {
                return ()
            }
        }()
        _ = await (eventsLoaded, profilesLoaded)
        userProfileStream()
        onReady?()
    }

        
    func stopSession() {
        profileStreamTask?.cancel()
        eventStreamTask?.cancel()
        userProfileStreamTask?.cancel()
        profiles.removeAll()
        invites.removeAll()
        events.removeAll()
        pastEvents.removeAll()
        session = nil
    }
    
    
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
    
    func userStream (appState: Binding<AppState>) {
        userStreamTask = Task { @MainActor in
            for await uid in authManager.authStateStream() {
                guard let uid else {
                    stopSession()
                    appState.wrappedValue = .login
                    defaultManager.deleteDefaults()
                    continue
                }
                guard let user = try? await userManager.fetchProfile(userId: uid) else {
                    appState.wrappedValue = .createAccount
                    session = nil
                    continue
                }
                await startSession(user: user) {
                    self.updateAppState(appState, for: user)
                }
                Task { await cacheManager.loadProfileImages([user]) }
            }
        }
    }
    
    func profilesStream(cycleId: String, onInitialLoad: (() -> Void)? = nil) async {
        profileStreamTask?.cancel()
        profileStreamTask = Task { @MainActor in
            do {
                let (initial, updates) = try await cycleManager.profilesTracker(userId: user.id, cycleId: cycleId)
                let ids = initial.compactMap(\.id)
                self.profiles = try await profileBuilder.fromIds(ids)
                onInitialLoad?()
                for try await update in updates {
                    switch update {
                    case .addProfile(id: let id):
                        if !profiles.contains(where: {$0.id == id }) {
                            let profile = try await profileBuilder.fromId(id)
                            profiles.append(profile)
                        }
                    case .removeProfile(id: let id):
                            profiles.removeAll(where: {$0.id == id})
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    func eventsStream(onInitialLoad: (() -> Void)? = nil) async {
        eventStreamTask?.cancel()
        eventStreamTask = Task { @MainActor in
            do {
                let (initial, updates) = try await eventManager.eventTracker(userId: user.id)
                
                let newInvites = initial.filter { $0.kind == .invite }.map { $0.event }
                let accepted = initial.filter { $0.kind == .accepted }.map { $0.event }
                let pastAccepted = initial.filter { $0.kind == .pastAccepted}.map { $0.event }
                
                do {
                    let (invModels, accModels, pastModels) = try await buildEvents(profileBuilder, invites: newInvites, accepted: accepted, past: pastAccepted)
                    self.invites = invModels
                    self.events  = accModels
                    self.pastEvents = pastModels
                } catch {
                    print(error)
                }
                
                for try await (event, kind) in updates {
                    switch kind {
                    case .invite:
                        if let newInvite = try? await profileBuilder.fromEvent(event) {
                            if !self.invites.contains(where: { $0.id == newInvite.id }) {
                                self.invites.append(newInvite)
                            }
                        }
                    case .accepted:
                        if let acceptedEvent = try? await profileBuilder.fromEvent(event) {
                            if !self.events.contains(where: { $0.id == acceptedEvent.id }) {
                                self.events.append(acceptedEvent)
                            }
                        }
                    case .pastAccepted:
                        if let pastEvent = try? await profileBuilder.fromEvent(event) {
                            if !self.pastEvents.contains(where: { $0.id == pastEvent.id }) {
                                self.pastEvents.append(pastEvent)
                            }
                        }
                    case .remove:
                        self.invites.removeAll { $0.id == event.otherUserId }
                        self.events.removeAll { $0.id == event.otherUserId }
                        self.pastEvents.removeAll { $0.id == event.otherUserId }
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}



/*

 func userProfileStream() {
     userProfileStreamTask?.cancel()
     userProfileStreamTask = Task { @MainActor in
         do {
             for try await change in userManager.userListener(userId: user.id) {
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
 */




struct Session {
    var user: UserProfile
    var invites: [ProfileModel] = []
    var profiles: [ProfileModel] = []
    var events: [UserEvent] = []
}



//Important that this is done of the main Thread, so function not in session Manager
func buildEvents(_ b: ProfileModelBuilder, invites: [UserEvent], accepted: [UserEvent], past: [UserEvent]) async throws -> ([ProfileModel],[ProfileModel],[ProfileModel]) {
    async let inv  = b.fromEvents(invites)
    async let acc  = b.fromEvents(accepted)
    async let past = b.fromEvents(past)
    return try await (inv, acc, past)
}
