//
//  EventViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import Foundation
import SwiftUI



@Observable class EventViewModel {
    
    var cacheManager: CacheManaging
    var userManager: UserManager
    var eventManager: EventManager
    var cycleManager: CycleManager
    var sessionManager: SessionManager
    
    
    init(cacheManager: CacheManaging, userManager: UserManager, eventManager: EventManager, cycleManager: CycleManager, sessionManager: SessionManager) {
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.eventManager = eventManager
        self.cycleManager = cycleManager
        self.sessionManager = sessionManager
    }
    
    var userEvents: [UserEvent] = []
    
    var hasEvents: Bool { !userEvents.isEmpty }
    var currentEvent: Event?
    var currentUser: UserProfile?
    
    func fetchUserEvents() async throws {
    }
    
    
    
    func saveUserImagesToCache() async throws {
        let ids = Set(userEvents.map(\.otherUserId))
        let profiles: [UserProfile] = try await withThrowingTaskGroup(of: UserProfile.self) { group in
            for id in ids {
                group.addTask { try await self.userManager.fetchUser(userId: id) } }
            var results: [UserProfile] = []
            for try await p in group { results.append(p) }
            return results
        }
        _ = await self.cacheManager.loadProfileImages(profiles)
        print("saved Images to Cache")
    }
    
    func testingCloudFunctions() async throws {
        
    }
    
}
