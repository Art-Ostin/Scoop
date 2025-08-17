//
//  SessionManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import SwiftUI



struct EventInvite {
    var event: UserEvent?
    var profile: UserProfile
    var image: UIImage?
    var id: String { profile.userId}
}


@Observable final class SessionManager {
    
    @ObservationIgnored private let eventManager: EventManager
    @ObservationIgnored private let cacheManager: CacheManaging
    @ObservationIgnored private let profileManager: ProfileManaging
    @ObservationIgnored private let userManager: UserManager
    @ObservationIgnored private let weeklyRecsManager: WeeklyRecsManager
    
    
    init(eventManager: EventManager, cacheManager: CacheManaging, profileManager: ProfileManaging, userManager: UserManager, weeklyRecsManager: WeeklyRecsManager) {
        self.eventManager = eventManager
        self.cacheManager = cacheManager
        self.profileManager = profileManager
        self.userManager = userManager
        self.weeklyRecsManager = weeklyRecsManager
    }
    
    var currentUser: UserProfile? {
        userManager.user
    }
    
    var profileRecs: [EventInvite] = []
    var profileInvites: [EventInvite] = []
    
    var userEvents: [Event] = []
    var pastEvents: [Event] = []
    
    var showWeeklyRecs: Bool?
    var showRespondToProfilesToRefresh: Bool?
    
    
    
    
    
    
    
    
    func loadProfileInvites() async {
        guard let events = try? await eventManager.getUpcomingInvitedEvents(), !events.isEmpty else { return }
        
        let results = await withTaskGroup(of: EventInvite?.self, returning: [EventInvite].self) {group in
            for e in events {
                group.addTask {
                    guard let p = try? await self.profileManager.getProfile(userId: e.otherUserId) else {return nil}
                    let firstImage = try? await self.cacheManager.fetchFirstImage(profile: p)
                    return EventInvite(event: e, profile: p, image: firstImage ?? UIImage())
                }
            }
            return await group.reduce(into: []) {result, element in if let element { result.append(element)}}
        }
        profileInvites = results
        await cacheManager.loadProfileImages(results.map(\.profile))
    }
    
    
    
    private func loadProfilesChecker () async throws -> Bool {
        
        let now = Date()
        let docs = try await weeklyRecsManager.getWeeklyRecDoc(currentUser)
        let timeEnd = docs.endsAt.dateValue()
        let timeRefresh = docs.autoRemoveTime.dateValue()
        
        let profilesAdded = docs.profilesAdded
        let profilesPending = docs.cycleStats.pending

        if now > timeEnd {
            if now > timeRefresh {
                try? await weeklyRecsManager.deleteWeeklyRec()
                showWeeklyRecs = false
                return false
            }
            
            if profilesPending == 0 {
                try? await weeklyRecsManager.deleteWeeklyRec()
                showWeeklyRecs = false
                return false
            } else {
                showRespondToProfilesToRefresh = true
                return true
            }
        }
        return true
    }

    func loadprofileRecs () async throws {
        
        guard
            let id = currentUser?.weeklyRecsId,
            try await loadProfilesChecker()
        else {
            showWeeklyRecs = false
            return
        }
        guard
            let documentId = currentUser?.weeklyRecsId,
            let ids = try? await weeklyRecsManager.getWeeklyItems()
        else { return }
        let results = await withTaskGroup(of: EventInvite?.self, returning: [EventInvite].self) { group in
            for item in ids {
                group.addTask {
                    guard
                        let item = item.id,
                        let p = try? await self.profileManager.getProfile(userId: item) else {return nil}
                    let firstImage = try? await self.cacheManager.fetchFirstImage(profile: p)
                    return EventInvite(event: nil, profile: p, image: firstImage ?? UIImage())
                }
            }
            return await group.reduce(into: []) {result, element in if let element { result.append(element)}}
        }
        profileRecs = results
        await cacheManager.loadProfileImages(results.map {$0.profile})
    }
    
    func removeProfileRec(profileId: String) {
        profileRecs.removeAll(where: {$0.id == profileId})
    }
    
}
