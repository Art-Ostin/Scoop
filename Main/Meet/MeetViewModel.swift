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
    let userManager: UserManager
    
    init(cycleManager: CycleManager, s: SessionManager, cacheManager: CacheManaging, eventManager: EventManager, userManager: UserManager) {
        self.cycleManager = cycleManager
        self.cacheManager = cacheManager
        self.s = s
        self.eventManager = eventManager
        self.userManager = userManager
    }
    
    var activeCycle: CycleModel? { s.activeCycle }
    
    var invites: [ProfileModel] { s.invites }
    
    var profiles: [ProfileModel] { s.profiles }
    
    var showProfilesState: showProfilesState? { s.showProfilesState }
    
    var endTime: Date? { activeCycle?.endsAt}
    
    func createWeeklyCycle() async throws {
        let id = try await cycleManager.createCycle(userId: s.user.id)
        try await s.beginCycle(withId: id)
    }
    
    func fetchImage(url: URL) async throws -> UIImage {
        try await cacheManager.fetchImage(for: url)
    }
    
    func updateEventStatus(eventId: String, status: EventStatus) async throws {
        try await eventManager.updateStatus(eventId: eventId, to: status)
    }
    
    func saveIdealMeetUp(event: EventDraft) async throws {
        guard
            let time = event.time,
            let place = event.location,
            let type = event.type
        else { return }
        let idealMeetUp = IdealMeetUp(time: time, place: place, type: type, message: event.message)
        try await userManager.updateUser(userId: s.user.id, values: [UserProfile.Field.idealMeetUp : idealMeetUp])
    }
}
