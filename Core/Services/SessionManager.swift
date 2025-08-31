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
                
                guard let user = try? await userManager.fetchUser(userId: uid) else {
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
    
    
    func loadCycle() async throws {
        let (status, cycle) = try await cycleManager.fetchCycleStatus(userId: user.id)
        switch status {
        case .closed:
            showProfilesState = .closed
            session?.activeCycle = nil
        case .respond:
            showProfilesState = .respond
            session?.activeCycle = cycle
        case .active:
            showProfilesState = .active
            session?.activeCycle = cycle
            print("cycle Active")
        }
    }
    
    
    func profilesStream() {
        profileStreamTask?.cancel()
        guard
            let userId = session?.user.id,
            let cycleId = session?.activeCycle?.id
        else { return }
        profileStreamTask = Task { @MainActor in
            do {
                for try await event in cycleManager.profilesStream(userId: userId, cycleId: cycleId){
                    switch event {
                    case .addProfile(let id):
                        try await loadProfile(id: id)
                        print("load profile called")
                    case .removeProfile(let id):
                        profiles.removeAll { $0.id == id }
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    func userEventsStream() {
        eventStreamTask?.cancel()
        eventStreamTask = Task { @MainActor in
            do{
                for try await event in eventManager.eventStream(userId: user.id) {
                    switch event {
                    case .removeInvite(let id):
                        invites.removeAll { $0.profile.id == id }
                        
                    case .eventInvite(let userEvent):
                        try await loadEvent(event: userEvent, field: \.invites)
                        
                    case .eventAccepted(let userEvent):
                        try await loadEvent(event: userEvent, field: \.events)
                        invites.removeAll(where: {$0.profile.id == userEvent.otherUserId})
                        
                    case .pastEventAccepted(let userEvent):
                        try await loadEvent(event: userEvent, field: \.pastEvents)
                        events.removeAll(where: {$0.profile.id == userEvent.otherUserId})
                    }
                }
            } catch {
                print (error)
            }
        }
    }

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

    
    private func loadEvent(event: UserEvent, field: ReferenceWritableKeyPath<SessionManager, [ProfileModel]>) async throws {
        let profile = try await userManager.fetchUser(userId: event.otherUserId)
        let firstImage = try? await cacheManager.fetchFirstImage(profile: profile)
        let model = ProfileModel(event: event, profile: profile, image: firstImage)
        var list = self[keyPath: field]
        guard !list.contains(where: { $0.id == event.id }) else { return }
        list.append(model)
        self[keyPath: field] = list
        Task { await cacheManager.loadProfileImages([profile]) }
    }

    private func loadProfile(id: String) async throws {
        guard !self.profiles.contains(where: { $0.profile.id == id }) else {
            print("didn't add")
            return
        }
        let profile = try await userManager.fetchUser(userId: id)
        let image = try await cacheManager.fetchFirstImage(profile: profile)
        let profileModel = ProfileModel(profile: profile, image: image)
        profiles.append(profileModel)
        print("profiles added")
        
        Task { await cacheManager.loadProfileImages([profile])}
    }

    func stopSession() {
        profileStreamTask?.cancel()
        userStreamTask?.cancel()
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
        stopSession() ; session = Session(user: user)
        
        do {try await loadCycle()} catch { print(error)}
        let userId = user.id
        let cycleId = session?.activeCycle?.id
        let em = eventManager, cm = cacheManager, cyc = cycleManager

        await withTaskGroup(of: Void.self) {group in

            group.addTask {
                guard let events = try? await em.getUpcomingInvitedEvents(userId: user.id), !events.isEmpty else { return }
                let input = events.map { (profileId: $0.otherUserId, event: $0) }
                let invites = await cyc.profileLoader(data: input)
                await MainActor.run { self.invites = invites }
                Task.detached { await cm.loadProfileImages(invites.map(\.profile)) }
            }
            
            group.addTask {
                guard let events = try? await em.getUpcomingAcceptedEvents(userId: user.id) else {return}
                let input = events.map { (profileId: $0.otherUserId, event: $0) }
                let profileModels = await cyc.profileLoader(data: input)
                await MainActor.run { self.events = profileModels }
                Task.detached {await cm.loadProfileImages(profileModels.map(\.profile))}
            }
            
            group.addTask {
                guard let events = try? await em.getPastAcceptedEvents(userId: user.id) else {return}
                let input = events.map { (profileId: $0.otherUserId, event: $0) }
                let profileModels = await cyc.profileLoader(data: input)
                await MainActor.run { self.pastEvents = profileModels }
                Task.detached { await MainActor.run { self.pastEvents = profileModels } }
            }
            
            if let cycleId {
                group.addTask {
                    guard let ids = try? await cyc.fetchCycleProfiles(userId: user.id, cycleId: cycleId), !ids.isEmpty else {return}
                    let data = ids.map { (profileId: $0, event: nil as UserEvent?) }
                    let profileModels = await cyc.profileLoader(data: data)
                    await MainActor.run { self.profiles = profileModels }
                    Task.detached { await cm.loadProfileImages(profileModels.map(\.profile)) }
                }
            }
        }
        
        cycleStream()
        userEventsStream()
        if cycleId != nil { profilesStream() }
    }
}




struct Session {
    var user: UserProfile
    var invites: [ProfileModel] = []
    var profiles: [ProfileModel] = []
    var events: [UserEvent] = []
    var activeCycle: CycleModel?
}



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
