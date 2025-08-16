//
//  MeetUpViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import Foundation
import SwiftUI


struct EventInvite {
    var event: UserEvent?
    var profile: UserProfile
    var image: UIImage
    var id: String { profile.userId}
    init(_ profile: UserProfile, _ event: UserEvent, _ image: UIImage) { self.profile = profile ; self.event = event ; self.image = image}
}


@Observable class MeetViewModel {
    
    var dep: AppDependencies
    var profileRecs: [EventInvite] = []
    var profileInvites: [EventInvite] = []
    
    var time: Date?
    
    init(dep: AppDependencies) {
        self.dep = dep
        self.time = dep.defaultsManager.getSuggestedProfilesTimer()
        Task {
            if profileRecs.isEmpty { await loadProfileRecs() }
            if profileInvites.isEmpty { await loadEventInvites() }
        }
    }
    
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
    
    func loadEventInvites() async {
        
        guard let events = try? await dep.eventManager.getUpcomingInvitedEvents(), !events.isEmpty else { return }
        
        let results = await withTaskGroup(of: EventInvite?.self, returning: [EventInvite].self) {group in
            for e in events {
                group.addTask {
                    guard let p = try? await self.dep.profileManager.getProfile(userId: e.otherUserId) else {return nil }
                        return EventInvite(p, e)
                    }
                }
            return await group.reduce(into: []) {result, element in if let element { result.append(element)}}
            }
        profileInvites = results
        await dep.cacheManager.loadProfileImages(results.map(\.profile))
    }
}
