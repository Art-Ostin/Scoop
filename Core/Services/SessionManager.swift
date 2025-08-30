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
    private var profileStreamTask: Task<Void, Never>?
    private var eventStreamTask: Task<Void, Never>?
    private var cycleStreamTask: Task<Void, Never>?
    
    var showProfilesState: showProfilesState = .closed
    
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

    
    
    //Loads user & listener to update the App State if user signs out, creates account, creates profile etc.
    func loadUserAndUserListener (appState: Binding<AppState>) {
        userStreamTask?.cancel()
        userStreamTask = Task { @MainActor in
            for await uid in authManager.authStateStream() {
                
                guard let uid else {
                    appState.wrappedValue = .login //  User
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
    
    
    
    // Loads the profiles, and updates profiles if invited or not
    func loadProfiles() async {
        guard
            let cycleId = session?.activeCycle?.id,
            let ids = try? await cycleManager.fetchCycleProfiles(userId: user.id, cycleId: cycleId)
        else {return}
        let uniqueIds = Set(Array(ids))
        let data = uniqueIds.map { (id: $0, event: nil as UserEvent?)}
        self.profiles = await profileLoader(data: data)
        Task {await cacheManager.loadProfileImages( self.profiles.map{$0.profile})}
    }
    
    func profilesListener() {
        profileStreamTask?.cancel()
        guard
            let userId = session?.user.id,
            let cycleId = session?.activeCycle?.id
        else { return }
        profileStreamTask = Task { @MainActor in
            do {
                for try await event in cycleManager.pendingProfilesStream(userId: userId, cycleId: cycleId){
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
    
    private func loadProfile(id: String) async throws {
        let profile = try await userManager.fetchUser(userId: id)
        Task { await cacheManager.loadProfileImages([profile]) }
        let profileModel = ProfileModel(profile: profile)
        profiles.append(profileModel)
    }

    
    
    // Load the events, Invites and Past Accepted and the listener to change their respective field
    func loadEventInvites() async {
        guard let events = try? await eventManager.getUpcomingInvitedEvents(userId: user.id), !events.isEmpty else { return }
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let invites = await profileLoader(data: input)
        self.invites = invites
        Task { await cacheManager.loadProfileImages(invites.map(\.profile)) }
    }
    func loadEventInvite(userEvent: UserEvent) async {
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let profileModel = await profileLoader(data: input)
        for profile in profileModel { //It has to return a [ProfileModels] even though it will be one
            invites.append(profile)
        }
        await cacheManager.loadProfileImages(profileModel.map(\.profile))
    }
    
    func loadAcceptedEvents() async {
        guard let events = try? await eventManager.getUpcomingAcceptedEvents(userId: user.id) else {return}
        self.events = events
        Task {
            let input = events.map { (id: $0.otherUserId, event: $0) }
            let profileModels = await profileLoader(data: input)
            await cacheManager.loadProfileImages(profileModels.map(\.profile))
        }
    }
    func loadAcceptedEvent(event: UserEvent) async {
        guard self.events.contains(where: { $0.id == event.id }) == false else { return }
        self.events.append(event)
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let profileModels = await profileLoader(data: input)
        await cacheManager.loadProfileImages(profileModels.map(\.profile))
    }
    
    func loadPastAcceptedEvents() async {
        guard let events = try? await eventManager.getPastAcceptedEvents(userId: user.id) else {return}
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let profileModels = await profileLoader(data: input)
        self.pastEvents = profileModels
    }
    func loadPastAcceptedEvent(event: UserEvent) async {
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let profileModels = await profileLoader(data: input)
        if let profile = profileModels.first {
            self.pastEvents.append(profile)

        }
    }

    func userEventsListener() {
        eventStreamTask?.cancel()
        eventStreamTask = Task { @MainActor in
            do{
                for try await event in eventManager.eventStream(userId: user.id) {
                    switch event {
                    case .removeInvite(let id):
                        invites.removeAll { $0.profile.id == id }
                        
                    case .newInvite(let userEvent):
                        await loadEventInvite(userEvent: userEvent)
                        
                    case .eventAccepted(let userEvent):
                        removeInvite(userEvent: userEvent)
                        await loadAcceptedEvent(event: userEvent)
                        
                    case .addPastAccepted(let userEvent):
                        removeAccepted(userEvent: userEvent)
                        await loadPastAcceptedEvent(event: userEvent)
                    }
                }
            } catch {
                print (error)
            }
        }
    }
    
    func removeInvite(userEvent: UserEvent) {
        let ids = invites.map { $0.event?.id }
        if ids.contains(userEvent.id) {
            invites.removeAll { $0.event?.id == userEvent.id }
        }
    }
    func removeAccepted(userEvent: UserEvent) {
        let ids = events.map { $0.id }
        if ids.contains(userEvent.id) {
            events.removeAll { $0.id == userEvent.id}
        }
    }
    
    
    
    // Load the user's Cycle, and updates UI if there is change during user session
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
    
    func cycleListener() {
        cycleStreamTask = Task {@MainActor in
            do{
                for try await update in cycleManager.cycleStream(userId: user.id) {
                    switch update {
                        
                    case .added(let cycle):
                        showProfilesState = .active
                        session?.activeCycle = cycle
                        
                    case .respond(let id):
                        if session?.activeCycle?.id == id {
                            showProfilesState = .respond
                        }
                        
                    case .closed(let id):
                        if session?.activeCycle?.id == id {
                            showProfilesState = .closed
                            session?.activeCycle = nil
                        }
                    }
                }
            } catch {
                print (error)
            }
        }
    }
    
    // Session starter and loading to ProfileModels
    func startSession(user: UserProfile) async throws {
        userStreamTask?.cancel()
        session = Session(user: user)
        try await loadCycle()
        
        async let events: ()  = loadAcceptedEvents()
        async let invites: ()  = loadEventInvites()
        async let profiles: () = loadProfiles()
        async let pastEvents: () = loadAcceptedEvents()
        _ =  await (events, invites, profiles, pastEvents)
        
        userEventsListener()
        profilesListener()
        cycleListener()
        
        Task { await cacheManager.loadProfileImages([user]) }
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
