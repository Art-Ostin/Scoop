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
    var image: UIImage
    var id: String { profile.userId}
}


@Observable final class SessionManager {
    
    var eventManager: EventManager
    var cacheManager: CacheManaging
    var profileManager: ProfileManaging
    var userManager: UserManager
    var weeklyRecsManager: WeeklyRecsManager
    
    
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
    
    
    
    
    
    func loadprofileRecs () async {
        guard
            let documentId = currentUser?.weeklyRecsId,
            let ids = try? await weeklyRecsManager.getWeeklyItems(weeklyCycleId: documentId)
        else { return }
        
        let results = await withTaskGroup(of: EventInvite?.self, returning: [EventInvite].self) { group in
            for id in ids {
                guard
                    let id,
                    let p = try? await self.profileManager.getProfile(userId: id) else {return nil}
                let firstImage = try? await self.cacheManager.fetchFirstImage(profile: p)
                return EventInvite(event: nil, profile: p, image: firstImage)
            }
            return await group.reduce(into: []) {result, element in if let element { result.append(element)}}
        }
        profileInvites = results
        await cacheManager.loadProfileImages(results.map($0.profile))
    }
    
    
    
    
    
    
}


/*
 func loadProfileRecs() async {
     
     let manager = dep.defaultsManager
     let ids = manager.getSuggestedProfiles()
     
     guard time != nil else {
         manager.removeAllSuggestedProfiles()
         profileRecs = []
         return
     }
     
     let results = await withTaskGroup(of: UserProfile?.self, returning: [UserProfile].self) { group in
         for id in ids {
             group.addTask { try? await self.dep.profileManager.getProfile(userId: id) }
         }
         return await group.reduce(into: []) { result, element in if let element { result.append(element) } }
     }
     profileRecs = results
     await dep.cacheManager.loadProfileImages(results)
     
     print("Function successfully called")
 }

 func updateTwoDailyProfiles() async {
     guard let newProfiles = try? await dep.profileManager.getRandomProfile() else { return }
     await dep.cacheManager.loadProfileImages(newProfiles)
     profileRecs = newProfiles
     dep.defaultsManager.setSuggestedProfiles(newProfiles)
 }

 
 */
