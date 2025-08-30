//
//  MeetViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/08/2025.

import Foundation
import UIKit

@MainActor
@Observable final class MeetViewModel {
        
    let cycleManager: CycleManager
    let cacheManager: CacheManaging
    let s: SessionManager
    let eventManager: EventManager
    
    init(cycleManager: CycleManager, s: SessionManager, cacheManager: CacheManaging, eventManager: EventManager) {
        self.cycleManager = cycleManager
        self.s = s
        self.cacheManager = cacheManager
        self.eventManager = eventManager
    }
    
    var activeCycle: CycleModel? { s.activeCycle }
    
    var invites: [ProfileModel] { s.invites }
    
    var profiles: [ProfileModel] { s.profiles }
    
    var showProfilesState: showProfilesState { s.showProfilesState }
    
    var endTime: Date? { activeCycle?.endsAt.dateValue()}
    
    
    func createWeeklyCycle() async throws {
        try await cycleManager.createCycle(userId: s.user.id)
    }
    
    func fetchImage(url: URL) async throws -> UIImage {
        try await cacheManager.fetchImage(for: url)
    }
    
    func updateEventStatus(eventId: String, status: EventStatus) async throws {
        try await eventManager.updateStatus(eventId: eventId, to: status)
    }
}
