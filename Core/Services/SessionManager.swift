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
    
    
    init(eventManager: EventManager, cacheManager: CacheManaging, userManager: UserManager, cycleManager: CycleManager, authManager: AuthManaging, defaultManager: DefaultsManager) {
        self.eventManager = eventManager
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.cycleManager = cycleManager
        self.authManager = authManager
        self.defaultManager = defaultManager
    }
    
    var showProfilesState: showProfilesState = .closed

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
    
    func userStream (appState: Binding<AppState>) {
        userStreamTask?.cancel()
        userStreamTask = Task { @MainActor in
            for await uid in authManager.authStateStream() {
                
                guard let uid else {
                    appState.wrappedValue = .login
                    userStreamTask?.cancel()
                    defaultManager.deleteDefaults()
                    continue
                }
                
                guard let user = try? await userManager.fetchUser(userId: uid) else {
                    appState.wrappedValue = .createAccount
                    session = nil
                    continue
                }
                
                startSession(user: user)
                appState.wrappedValue = .app
                Task { await cacheManager.loadProfileImages([user]) }
            }
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
                        await loadEventInvite(userEvent: userEvent)
                        
                    case .eventAccepted(let userEvent):
                        await loadAcceptedEvent(event: userEvent)
                        
                    case .pastEventAccepted(let userEvent):
                        await loadPastAcceptedEvent(event: userEvent)
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
    
    private func loadProfile(id: String) async throws {
        guard profiles.contains(where: { $0.id == id }) == false else { return }
        let profile = try await userManager.fetchUser(userId: id)
        Task { await cacheManager.loadProfileImages([profile]) }
        let profileModel = ProfileModel(profile: profile)
        profiles.append(profileModel)
        print("profile Loaded")
    }
    
    func loadEventInvite(userEvent: UserEvent) async {
        let input = events.map { (profileId: $0.otherUserId, event: $0) }
        let profileModel = await profileLoader(data: input)
        for profile in profileModel { //It has to return a [ProfileModels] even though it will be one
            invites.append(profile)
        }
        await cacheManager.loadProfileImages(profileModel.map(\.profile))
    }
    
    func loadAcceptedEvent(event: UserEvent) async {
        let ids = invites.map { $0.event?.id }
        if ids.contains(event.id) { invites.removeAll { $0.event?.id == event.id }}
        
        guard self.events.contains(where: { $0.id == event.id }) == false else { return }
        self.events.append(event)
        let input = events.map { (profileId: $0.otherUserId, event: $0) }
        let profileModels = await profileLoader(data: input)
        await cacheManager.loadProfileImages(profileModels.map(\.profile))
    }
    
    func loadPastAcceptedEvent(event: UserEvent) async {
        let ids = events.map { $0.id }
        if ids.contains(event.id) { events.removeAll { $0.id == event.id}}
        
        let input = events.map { (profileId: $0.otherUserId, event: $0) }
        let profileModels = await profileLoader(data: input)
        if let profile = profileModels.first {
            self.pastEvents.append(profile)
        }
    }

    // Session starter and loading to ProfileModels
    
    func stopSession() {
        profileStreamTask?.cancel()
        userStreamTask?.cancel()
        eventStreamTask?.cancel()
        cycleStreamTask?.cancel()
        profiles.removeAll()
        invites.removeAll()
        events.removeAll()
        pastEvents.removeAll()
        session = nil
    }

    func startSession(user: UserProfile) {
        stopSession()
        session = Session(user: user)

        cycleStream()
        userEventsStream()
        profilesStream()
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

func loadPastAcceptedEvents() async {
    guard let events = try? await eventManager.getPastAcceptedEvents(userId: user.id) else {return}
    let input = events.map { (profileId: $0.otherUserId, event: $0) }
    let profileModels = await profileLoader(data: input)
    self.pastEvents = profileModels
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

