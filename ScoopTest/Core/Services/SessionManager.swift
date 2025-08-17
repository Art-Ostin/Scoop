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

    
    var showWeeklyRecs: Bool?
    var showRespondToProfilesToRefresh: Bool?
    
    
    func loadProfileInvites() async {
        print("Load ProfileInvitesCalled")
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
    
    
    private func loadProfileRecsChecker () async -> Bool {

        print("Step 2.0: Checking if weekly users")
        guard let _ = currentUser?.weeklyRecsId else {
            showWeeklyRecs = false
            
            print("No weekly users to load, returned false")
            return false
        }
        
        guard let doc = try? await weeklyRecsManager.getWeeklyRecDoc(currentUser) else {
            showWeeklyRecs = false
            return false
        }
        
        let timeEnd = doc.endsAt.dateValue()
        let timeRefresh = doc.autoRemoveTime.dateValue()

        let profilesPending = doc.cycleStats.pending

        if Date() > timeEnd {
            if Date() > timeRefresh {
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
        } else {
            return true
        }
    }
    
    func loadprofileRecs () async throws {
        
        guard await loadProfileRecsChecker() else {
            print("no weekly users")
            return
        }
        
        profileRecs = try await 

        
        profileRecs = results
        await cacheManager.loadProfileImages(results.map {$0.profile})
        print("Step 2.1.1: Load profile recs completed")
    }
    
    
        
    func removeProfileRec(profileId: String) {
        profileRecs.removeAll(where: {$0.id == profileId})
    }
    
}




//let weeklyProfiles = try await weeklyRecsManager.getWeeklyItems()
//
//let results = await withTaskGroup(of: EventInvite?.self, returning: [EventInvite].self) { group in
//    for item in weeklyProfiles {
//        group.addTask {
//            guard
//                let p = try? await self.profileManager.getProfile(userId: item.id) else {return nil}
//            let firstImage = try? await self.cacheManager.fetchFirstImage(profile: p)
//            return EventInvite(event: nil, profile: p, image: firstImage ?? UIImage())
//        }
//    }
//    return await group.reduce(into: []) {result, element in if let element { result.append(element)}}
//}
