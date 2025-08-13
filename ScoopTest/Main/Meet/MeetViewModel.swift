//
//  MeetUpViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import Foundation
import SwiftUI
import AsyncAlgorithms

@Observable class MeetViewModel {
    
    var dep: AppDependencies
    var profileRecs: [UserProfile] = []
    var profileInvites: [(UserProfile, UserEvent)] = []
    
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
        guard let userInvites = try? await dep.eventManager.getUpcomingInvitedEvents() else { return}
        if userInvites.isEmpty == true { return }

        await withTaskGroup(of: UserProfile?.self) { group in
            for event in userInvites {
                group.addTask { try? await self.dep.profileManager.getProfile(userId: event.otherUserId) }
                for await profile in group {
                    if let profile {
                        profileInvites.append((profile, event))
                        await dep.cacheManager.loadProfileImages([profile])
                    }
                }
            }
        }
    }
}
