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
    
    private let eventManager: EventManager
    private let cacheManager: CacheManaging
    private let userManager: UserManager
    private let cycleManager: CycleManager
    private let authManager: AuthManaging
    private let defaultManager: DefaultsManager
    private let profileBuilder: ProfileModelBuilder
    
    private(set) var session: Session?
    
    private var userStreamTask: Task<Void, Never>?
    private var profileStreamTask: Task<Void, Never>?
    private var eventStreamTask: Task<Void, Never>?
    private var cycleStreamTask: Task<Void, Never>?
    private var userProfileStreamTask: Task<Void, Never>?
    
    var showProfilesState: showProfilesState?
    
    var activeCycle: CycleModel? { session?.activeCycle }
    
    var user: UserProfile {
        guard let session else { fatalError("Session not started") }
        return session.user
    }
    
    var profiles: [ProfileModel] = []
    var invites: [ProfileModel] = []
    var events: [ProfileModel] = []
    var pastEvents: [ProfileModel] = []
    
    init(eventManager: EventManager, cacheManager: CacheManaging, userManager: UserManager, cycleManager: CycleManager, authManager: AuthManaging, defaultManager: DefaultsManager) {
        self.eventManager = eventManager
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.cycleManager = cycleManager
        self.authManager = authManager
        self.defaultManager = defaultManager
        self.profileBuilder = ProfileModelBuilder(userManager: userManager, cache: cacheManager)
    }
    
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
                await startSession(user: user)
                appState.wrappedValue = .app
                Task { await cacheManager.loadProfileImages([user]) }
            }
        }
    }
    
    func loadCycle(userId: String) async -> String? {
        do {
            let (status, cycle) = try await cycleManager.fetchCycleStatus(user: user)
            switch status {
            case .active, .respond:
                session?.activeCycle = cycle
                showProfilesState = (status == .active ? .active : .respond)
                if let cycleId = cycle?.id {
                    cycleStream(userId: userId, cycleId: cycleId)
                    return cycleId
                }
            case .closed:
                showProfilesState = .closed
                session?.activeCycle = nil
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    func beginCycle(withId id: String) async throws {
        showProfilesState = .active
        cycleStream(userId: user.id, cycleId: id)
        do {
            let model = try await cycleManager.fetchCycleModel(userId: user.id, cycleId: id)
            session?.activeCycle = model
            await profilesStream(cycleId: id)
        } catch {
            print(error)
        }
    }

    func cycleStream(userId: String, cycleId: String) {
        cycleStreamTask?.cancel()
        cycleStreamTask = Task { @MainActor in
            do {
                for try await cycle in cycleManager.cycleListener(userId: userId, cycleId: cycleId) {
                    guard let cycleUpdate = cycle else { return }
                    switch cycleUpdate.cycleStatus {
                    case .respond:
                        showProfilesState = .respond
                    case .closed:
                        showProfilesState = .closed
                        session?.activeCycle = nil
                        return //Important: Closes the listener on the cycle document when its done
                    case .active:
                        continue
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    func profilesStream(cycleId: String) async {
        profileStreamTask?.cancel()
        profileStreamTask = Task { @MainActor in
            do {
                let (initial, updates) = try await cycleManager.profilesTracker(userId: user.id, cycleId: cycleId)
                let ids = initial.compactMap(\.id)
                self.profiles = try await profileBuilder.fromIds(ids)

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
    
    func userEventsStream() async {
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
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    func userProfileStream() {
        userProfileStreamTask?.cancel()
        userProfileStreamTask = Task { @MainActor in
            do {
                for try await change in userManager.userListener(userId: user.id) {
                    if let change {
                        session?.user = change
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    func stopSession() {
        profileStreamTask?.cancel()
        eventStreamTask?.cancel()
        cycleStreamTask?.cancel()
        userProfileStreamTask?.cancel()
        profiles.removeAll()
        invites.removeAll()
        events.removeAll()
        pastEvents.removeAll()
        session = nil
    }
    
    func startSession(user: UserProfile) async {
        stopSession() ;
        session = Session(user: user)
        if let id = await loadCycle(userId: user.id) { await profilesStream(cycleId: id) }
        await userEventsStream()
        userProfileStream()
    }
}


struct Session {
    var user: UserProfile
    var invites: [ProfileModel] = []
    var profiles: [ProfileModel] = []
    var events: [UserEvent] = []
    var activeCycle: CycleModel?
}


//Important that this is done of the main Thread, so function not in session Manager
func buildEvents(_ b: ProfileModelBuilder, invites: [UserEvent], accepted: [UserEvent], past: [UserEvent]) async throws -> ([ProfileModel],[ProfileModel],[ProfileModel]) {
    async let inv  = b.fromEvents(invites)
    async let acc  = b.fromEvents(accepted)
    async let past = b.fromEvents(past)
    return try await (inv, acc, past)
}




/*
    private func loadProfile(id: String) async throws {
        guard !self.profiles.contains(where: { $0.profile.id == id }) else {
            print("didn't add")
            return
        }
        let profile = try await userManager.fetchUser(userId: id)
        let image = try await cacheManager.fetchFirstImage(profile: profile)
        let profileModel = ProfileModel(profile: profile, image: image)
        profiles.append(profileModel)
        
        Task { await cacheManager.loadProfileImages([profile])}
    }
    */

/*
 func loadAcceptedEvent(event: UserEvent) async throws {
     guard !events.contains(where: { $0.id == event.id }) else {return }
     let profile = try await userManager.fetchUser(userId: event.otherUserId)
     let firstImage = try? await cacheManager.fetchFirstImage(profile: profile)
     let profileModel = ProfileModel(event: event, profile: profile, image: firstImage)
     events.append(profileModel)
     Task  {await cacheManager.loadProfileImages([profile])}
 }
 
 func loadPastAcceptedEvent(event: UserEvent) async throws {
     guard !pastEvents.contains(where: { $0.id == event.id }) else {return }
     let profile = try await userManager.fetchUser(userId: event.otherUserId)
     let firstImage = try? await cacheManager.fetchFirstImage(profile: profile)
     let profileModel = ProfileModel(event: event, profile: profile, image: firstImage)
     pastEvents.append(profileModel)
     Task {await cacheManager.loadProfileImages([profile])}
 }
 */

/*
 func loadEventInvites() async {
     guard let events = try? await eventManager.getUpcomingInvitedEvents(userId: user.id), !events.isEmpty else { return }
     let input = events.map { (profileId: $0.otherUserId, event: $0) }
     let invites = await cycleManager.profileLoader(data: input)
     self.invites = invites
     Task { await cacheManager.loadProfileImages(invites.map(\.profile)) }
 }

 func loadPastAcceptedEvents() async {
     guard let events = try? await eventManager.getPastAcceptedEvents(userId: user.id) else {return}
     let input = events.map { (profileId: $0.otherUserId, event: $0) }
     let profileModels = await profileLoader(data: input)
     self.pastEvents = profileModels
 }
     
 func loadAcceptedEvents() async {
     guard let events = try? await eventManager.getUpcomingAcceptedEvents(userId: user.id) else {return}
     let input = events.map { (profileId: $0.otherUserId, event: $0) }
     let profileModels = await cycleManager.profileLoader(data: input)
     self.events = profileModels
     Task {await cacheManager.loadProfileImages(profileModels.map(\.profile))}
 }
 
 func loadProfiles(cycleId: String) async throws {
     let ids = try await cycleManager.fetchCycleProfiles(userId: user.id, cycleId: cycleId)
     let data = ids.map { (profileId: $0, event: nil as UserEvent?) }
     let profileModels = await cycleManager.profileLoader(data: data)
     self.profiles = profileModels
     Task { await cacheManager.loadProfileImages(profileModels.map(\.profile)) }
 }
 */

/*
 func profilesStream() {
     profileStreamTask?.cancel()
     guard
         let userId = session?.user.id,
         let cycleId = session?.activeCycle?.id
     else { return }
     profileStreamTask = Task { @MainActor in
         //            do {
         //                for try await event in cycleManager.profilesStream(userId: userId, cycleId: cycleId){
         //                    switch event {
         //                    case .addProfile(let id):
         //                        try await loadProfile(id: id)
         //                    case .removeProfile(let id):
         //                        profiles.removeAll { $0.id == id }
         //                    }
         //                }
         //            } catch {
         //                print(error)
         //            }
     }
 }
 */

/*
 do {try await loadCycle()} catch { print(error)}
 let cycleId = session?.activeCycle?.id
 if cycleId != nil { profilesStream() }
 let em = eventManager, cm = cacheManager, cyc = cycleManager
 
 await withTaskGroup(of: Void.self) {group in
     
     if let cycleId {
         print("There is a cycleId")
         group.addTask {
             guard let ids = try? await cyc.fetchCycleProfiles(userId: user.id, cycleId: cycleId), !ids.isEmpty else {return}
             let data = ids.map { (profileId: $0, event: nil as UserEvent?) }
             let profileModels = await cyc.profileLoader(data: data)
             await MainActor.run {
                 self.profiles = profileModels
                 for profile in self.profiles {
                     print(profile.profile.name)
                 }
             }
             Task.detached { await cm.loadProfileImages(profileModels.map(\.profile)) }
         }
     }
 }
 cycleStream()
 userEventsStream()

 */

/*
 func cycleStream() {
     cycleStreamTask = Task {@MainActor in
         do{
             for try await update in cycleManager.cycleStream(userId: user.id) {
                 switch update {
                     
                 case .added(let cycle):
                     showProfilesState = .active
                     session?.activeCycle = cycle
                     profiles.removeAll()
                     profilesStream()
                     
                 case .respond(let id):
                     if session?.activeCycle?.id == id {
                         showProfilesState = .respond
                     }
                     
                 case .closed(let id):
                     if session?.activeCycle?.id == id {
                         showProfilesState = .closed
                         session?.activeCycle = nil
                         profiles.removeAll()
                         profileStreamTask?.cancel()
                     }
                 }
             }
         } catch {
             print (error)
         }
     }
 }
 */
