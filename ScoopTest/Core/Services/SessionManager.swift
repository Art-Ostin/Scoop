//
//  SessionManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import SwiftUI

struct Session  {
    var user: UserProfile
    var invites: [ProfileModel] = []
    var profiles: [ProfileModel] = []
    var events: [UserEvent] = []
    var activeCycle: CycleModel?
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
    private var authStreamTask: Task<Void, Never>?
    private var cycleStreamTask: Task<Void, Never>?
    private var eventStreamTask: Task<Void, Never>?
    private var cycleStreamTask: Task<Void, Never>?
    
    var showProfiles: Bool = true
    var respondToRefresh: Bool = false
    
    init(eventManager: EventManager, cacheManager: CacheManaging, userManager: UserManager, cycleManager: CycleManager, authManager: AuthManaging, defaultManager: DefaultsManager) {
        self.eventManager = eventManager
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.cycleManager = cycleManager
        self.authManager = authManager
        self.defaultManager = defaultManager
    }
    
    var profiles: [ProfileModel] = []
    var invites: [ProfileModel] = []
    var events: [UserEvent] = []
    var pastEvents: [ProfileModel] = []
    
    var activeCycle: CycleModel? { session?.activeCycle }
    var user: UserProfile {
        guard let session else { fatalError("Session not started") }
        return session.user
    }
    
    
    func AuthUserListener(appState: Binding<AppState>) {
        authStreamTask?.cancel()
        authStreamTask = Task { @MainActor in
            for await uid in authManager.authStateStream() {
                print("auth State called")
                
                guard let uid else {
                    appState.wrappedValue = .login // Logsin User
                    userStreamTask?.cancel()
                    defaultManager.deleteDefaults()
                    continue
                }
                
                guard let user = try? await userManager.fetchUser(userId: uid) else {
                    appState.wrappedValue = .createAccount
                    session = nil
                    continue
                }
                try? await startSession(user: user)
                appState.wrappedValue = .app
            }
        }
    }
    
    func startSession(user: UserProfile) async throws {
        session = Session(user: user)
        userStreamTask?.cancel()
        
        try await loadCycle()
        
        async let events: ()  = loadEvents()
        async let invites: ()  = loadInvites()
        async let profiles: () = loadProfiles()
        async let pastEvents: () = loadPastEvents()
        _ = try await (events, invites, profiles, pastEvents)
        Task { await cacheManager.loadProfileImages([user]) }
        
        startUserStream(for: user.id)
        profilesListener()
        eventsListener()
    }
    
    private func startUserStream(for userId: String) {
        userStreamTask = Task { @MainActor in
            do {
                for try await profile in userManager.userListener(userId: userId) {
                    if let profile { self.session?.user = profile }
                    else { break }
                }
            } catch {
                print (error)
            }
        }
    }
    
    //Load Profile
    func profilesListener() {
        guard
            let userId = session?.user.id,
            let cycleId = session?.activeCycle?.id
        else { return }
        cycleStreamTask?.cancel()
        cycleStreamTask = Task { @MainActor in
            do {
                for try await event in cycleManager.pendingProfilesStream(userId: userId, cycleId: cycleId){
                    switch event {
                    case .addedPending(let id):
                        try await loadProfile(id: id)
                    case .movedToInvite(let id):
                        profiles.removeAll { $0.id == id }
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    
    private func loadProfile(id: String) async throws {
        let profile = try await userManager.fetchUser(userId: id)
        Task { await cacheManager.loadProfileImages([profile]) }
        let profileModel = ProfileModel(profile: profile)
        profiles.append(profileModel)
    }
    
    func loadProfiles() async {
        guard
            let cycleId = session?.activeCycle?.id,
            let ids = try? await cycleManager.fetchCycleProfiles(userId: user.id, cycleId: cycleId)
        else {return}
        let data = ids.map { (id: $0, event: nil as UserEvent?)}
        profiles = await profileLoader(data: data)
        
        Task {await cacheManager.loadProfileImages( self.profiles.map{$0.profile})}
    }
        
        
    func eventsListener() {
        eventStreamTask?.cancel()
        eventStreamTask = Task { @MainActor in
            do{
                for try await event in eventManager.eventStream(userId: user.id) {
                    switch event {
                        
                    case .removePending(let id):
                        invites.removeAll { $0.profile.id == id }
                        
                    case .addAccepted(let userEvent):
                        await loadEvent(event: userEvent)
                        
                    case .addPastAccepted(let pastAccepted):
                        await loadPastEvent(event: pastAccepted)
                        
                    case .newInvite(let userEvent):
                        await loadInvite(userEvent: userEvent)
                    }
                }
            }catch {
                print (error)
            }
        }
    }
    

    func loadInvite(userEvent: UserEvent) async {
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let profileModel = await profileLoader(data: input)
        for profile in profileModel { //It has to return a [ProfileModels] even though it will be one
            invites.append(profile)
        }
        await cacheManager.loadProfileImages(profileModel.map(\.profile))
    }
    
    func loadInvites() async {
        guard let events = try? await eventManager.getUpcomingInvitedEvents(userId: user.id), !events.isEmpty else { return }
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let invites = await profileLoader(data: input)
        self.invites = invites
        Task { await cacheManager.loadProfileImages(invites.map(\.profile)) }
    }
    
    func loadEvent(event: UserEvent) async {
        self.events.append(event)
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let profileModels = await profileLoader(data: input)
        await cacheManager.loadProfileImages(profileModels.map(\.profile))
    }
    
    func loadEvents() async {
        guard let events = try? await eventManager.getUpcomingAcceptedEvents(userId: user.id) else {return}
        self.events = events
        Task {
            let input = events.map { (id: $0.otherUserId, event: $0) }
            let profileModels = await profileLoader(data: input)
            await cacheManager.loadProfileImages(profileModels.map(\.profile))
        }
    }
    
    func loadPastEvent(event: UserEvent) async {
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let profileModels = await profileLoader(data: input)
        if let profile = profileModels.first {
            self.pastEvents.append(profile)

        }
    }
    
    func loadPastEvents() async {
        guard let events = try? await eventManager.getPastAcceptedEvents(userId: user.id) else {return}
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let profileModels = await profileLoader(data: input)
        self.pastEvents = profileModels
    }
    
    func loadCycle() async throws {
        let (status, cycleModel) = try await cycleManager.checkCycleStatus(userId: user.id)
        if status == .closed { showProfiles = false ; respondToRefresh = false ; return }
        if status == .respond { showProfiles = true ; respondToRefresh = true ; return }
        if status == .active { session?.activeCycle = cycleModel }
    }
    
    
    //This should only be updating the variables in this file here
    
    
    func cycleListener() async {
        cycleStreamTask?.cancel()
        
        cycleStreamTask = Task { @MainActor in
            
            for try await cycle in cycleManager.weeklyCycleStream(userId: user.id) {
                switch cycle {
                case .added(let cycleModel):
                    session?.activeCycle = cycleModel
                    loadProfiles()
                case .closed(let newId):
                    guard let cycleId = session?.activeCycle.id else {return}
                    if cycleId = newId {
                        cycleManager.deleteCycle(userId: user.id, cycleId: cycleId)
                    }
                    
                case .pending(let id):
                    session.activeCycle == .pending
                }
            }
        }
    }
    
    
    
    
    func profileLoader(data: [(id: String, event: UserEvent?)]) async -> [ProfileModel] {
        return await withTaskGroup(of: ProfileModel?.self, returning: [ProfileModel].self) { group in
            for item in data {
                group.addTask {
                    guard let profile = try? await self.userManager.fetchUser(userId: item.id) else {return nil}
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



