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
    
    @Binding var refreshProfiles: Task<Void, Never>?
    
    init(dep: AppDependencies) {
        self.dep = dep
        Task { await loadTwoDailyProfiles()
            print("populated two daily Profiles") }
    }
    
    func scheduleCreateNextTwoDailyProfiles () {
        guard let time = dep.defaultsManager.getDailyProfileTimerEnd() else { return }
        let trigger = time.addingTimeInterval(-180)
        let delay = trigger.timeIntervalSinceNow

        if delay <= 0 { Task { await createNextTwoDailyProfiles() } }
        refreshProfiles = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled { await createNextTwoDailyProfiles() }
        }
    }
    
    func scheduleUpdateTwoDailyProfiles () {
        if dep.defaultsManager.getDailyProfileTimerEnd() != nil { return } else {
            Task { await updateTwoDailyProfiles() }
        }
    }
    
    
    func createNextTwoDailyProfiles() async {
        let profiles = try? await dep.profileManager.getRandomProfile()
        let ids = profiles?.map({ $0.userId }) ?? []
        dep.defaultsManager.setNextTwoDailyProfiles(ids)
        if let profiles {
            Task { await dep.cacheManager.loadProfileImages(profiles)}
        }
        print("Created next Two Daily Profiles")
    }
    
    
    func updateTwoDailyProfiles() async {
        let manager = dep.defaultsManager

        while true {
            let ids = manager.getNextTwoDailyProfiles()
            if ids.isEmpty {
                await createNextTwoDailyProfiles()
                continue
            }
            var newProfiles: [UserProfile] = []
            for id in ids {
                guard let p = try? await dep.profileManager.getProfile(userId: id) else { return }
                newProfiles.append(p)
            }
            shownDailyProfiles = newProfiles
            manager.setTwoDailyProfiles(newProfiles)
            manager.deleteNextTwoDailyProfiles()
        }
    }
    
    
    func loadTwoDailyProfiles() async {
        let ids = dep.defaultsManager.getTwoDailyProfiles()
        guard !ids.isEmpty else { shownDailyProfiles = []; return }
        
        var results: [UserProfile] = []
        await withTaskGroup(of: UserProfile?.self) { group in
            for id in ids {
                group.addTask { try? await self.dep.profileManager.getProfile(userId: id) }
            }
            for await p in group { if let p { results.append(p) } }
        }
        shownDailyProfiles = results
    }
}
