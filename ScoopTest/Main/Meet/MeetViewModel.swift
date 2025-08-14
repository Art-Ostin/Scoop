//
//  MeetUpViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import Foundation
import SwiftUI
import AsyncAlgorithms


struct EventInvite {
    var event: UserEvent
    var profile: UserProfile
    var id: String { event.id ?? "" }
    init(_ profile: UserProfile, _ event: UserEvent) { self.profile = profile ; self.event = event }
}


@Observable class MeetViewModel {
    
    var dep: AppDependencies
    var profileRecs: [UserProfile] = []
    var profileInvites: [EventInvite] = []
    
    init(dep: AppDependencies) { self.dep = dep }
    
    func loadProfileRecs() async {
        let manager = dep.defaultsManager
        guard manager.getDailyProfileTimerEnd() != nil else { manager.deleteTwoDailyProfiles() ; profileRecs = [] ; return }
        let ids = manager.getTwoDailyProfiles()
        let results = await withTaskGroup(of: UserProfile?.self, returning: [UserProfile].self) { group in
            for id in ids {
                group.addTask { try? await self.dep.profileManager.getProfile(userId: id) }
            }
            return await group.reduce(into: []) { result, element in if let element { result.append(element) } }
        }
        profileRecs = results
        await dep.cacheManager.loadProfileImages(results)
    }
    
    func updateTwoDailyProfiles() async {
        guard let newProfiles = try? await dep.profileManager.getRandomProfile() else { return }
        await dep.cacheManager.loadProfileImages(newProfiles)
        profileRecs = newProfiles
        dep.defaultsManager.setTwoDailyProfiles(newProfiles)
    }
    
    func loadEventInvites() async {
        guard let events = try? await dep.eventManager.getUpcomingInvitedEvents(), !events.isEmpty else { return }
        var out: [EventInvite] = []
        await withTaskGroup(of: EventInvite?.self) {group in
            for e in events {
                group.addTask {
                    guard let p = try? await self.dep.profileManager.getProfile(userId: e.otherUserId) else {return nil }
                        return EventInvite(p, e)
                    }
                }
            for await i in group { if let i { out.append(i) } }
            }
        profileInvites = out
        await dep.cacheManager.loadProfileImages(out.map(\.self.profile))
    }
}
