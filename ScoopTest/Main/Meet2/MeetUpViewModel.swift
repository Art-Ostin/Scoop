//
//  MeetUpViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import Foundation
import SwiftUI

@Observable class MeetUpViewModel2 {
    
    var dep: AppDependencies
    
    var shownDailyProfiles: [UserProfile] = []
    
    
    init(dep: AppDependencies) {
        self.dep = dep
            Task { await loadTwoDailyProfiles()}
    }

    func updateTwoDailyProfiles() async {
        let manager = dep.defaultsManager
        let profiles = try? await dep.profileManager.getRandomProfile()
        guard let newProfiles = profiles else { return }
        Task {await dep.cacheManager.loadProfileImages(newProfiles)}
        shownDailyProfiles = newProfiles
        manager.setTwoDailyProfiles(newProfiles)
    }
    
    //If the timer is still going load the two daily profiles. If not, remove the old two daily profiles
    func loadTwoDailyProfiles() async {
        let manager = dep.defaultsManager
        if manager.getDailyProfileTimerEnd() != nil {
            let ids = manager.getTwoDailyProfiles()
            var results: [UserProfile] = []
            await withTaskGroup(of: UserProfile?.self) { group in
                for id in ids {
                    group.addTask { try? await self.dep.profileManager.getProfile(userId: id) }
                }
                for await p in group { if let p { results.append(p) } }
            }
            Task { await dep.cacheManager.loadProfileImages(results) }
            shownDailyProfiles = results
            print("populated two daily profiles into the Meet Up view ")
        } else {
            manager.deleteTwoDailyProfiles()
            print("deleted two daily profiles")
        }
    }
    
    func loadInvites() async throws {
        print("starting load Invites")
        let pendingEvents = try await dep.eventManager.getInvitedEvents()

        try await withThrowingTaskGroup(of: UserProfile.self) { group in
            for event in pendingEvents {
                group.addTask { try await self.dep.eventManager.getEventMatch(event: event) }
            }
            var results: [UserProfile] = []
            for try await profile in group { results.append(profile) }
            shownDailyProfiles.append(contentsOf: results)
        }
        print("Finishing load Invites")
    }
}
