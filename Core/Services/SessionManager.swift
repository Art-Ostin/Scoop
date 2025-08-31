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
        }
    }
    
    func loadEventInvites() async {
        guard let events = try? await eventManager.getUpcomingInvitedEvents(userId: user.id), !events.isEmpty else { return }
        let input = events.map { (profileId: $0.otherUserId, event: $0) }
        let invites = await profileLoader(data: input)
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
        let profileModels = await profileLoader(data: input)
        self.events = profileModels
        Task {await cacheManager.loadProfileImages(profileModels.map(\.profile))}
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
        guard !profiles.contains(where: { $0.id == id }) else { return }
        let profile = try await userManager.fetchUser(userId: id)
        let image = try await cacheManager.fetchFirstImage(profile: profile)
        let profileModel = ProfileModel(profile: profile, image: image)
        profiles.append(profileModel)
        
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
        stopSession()
        session = Session(user: user)
        async let a: Void = loadCycle()
        async let b: Void = loadEventInvites()
        async let c: Void = loadAcceptedEvents ()
        async let d: Void = loadPastAcceptedEvents ()
        _ = try? await (a, b , c, d)
        
        cycleStream()
        userEventsStream()
        profilesStream()
        
        if session?.activeCycle != nil {  // profilesStream needs a cycleId
            profilesStream()
        }
    }

    func profileLoader(data: [(profileId: String, event: UserEvent?)]) async -> [ProfileModel] {
        return await withTaskGroup(of: ProfileModel?.self, returning: [ProfileModel].self) { group in
            for item in data {
                group.addTask {
                    guard let profile = try? await self.userManager.fetchUser(userId: item.profileId) else {return nil}
                    let image = try? await self.cacheManager.fetchFirstImage(profile: profile)
                    return ProfileModel(event: item.event, profile: profile, image: image ?? UIImage())
                }
            }
            return await group.reduce(into: []) {result, element  in
                if let element {result.append(element)}
            }
        }
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
 Load the user's Cycle, and updates UI if there is change during user session
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
        }
    }




func loadEventInvites() async {
    guard let events = try? await eventManager.getUpcomingInvitedEvents(userId: user.id), !events.isEmpty else { return }
    let input = events.map { (profileId: $0.otherUserId, event: $0) }
    let invites = await profileLoader(data: input)
    self.invites = invites
    Task { await cacheManager.loadProfileImages(invites.map(\.profile)) }
}



func loadAcceptedEvents() async {
    guard let events = try? await eventManager.getUpcomingAcceptedEvents(userId: user.id) else {return}
    self.events = events
    Task {
        let input = events.map { (profileId: $0.otherUserId, event: $0) }
        let profileModels = await profileLoader(data: input)
        await cacheManager.loadProfileImages(profileModels.map(\.profile))
    }
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
