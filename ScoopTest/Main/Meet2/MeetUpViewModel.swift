//
//  MeetUpViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import Foundation



@Observable class MeetUpViewModel2 {
    
    var dep: AppDependencies
    
    var shownProfiles: [UserProfile] = []
    
    private var profileTimerTask: Task<Void, Never>?
    
    init(dep: AppDependencies) {
        self.dep = dep
        scheduleStoredDailyTimer()
    }
    
    func createTwoDailyProfiles() async {
        let profiles = try? await dep.profileManager.getRandomProfile()
        if let profiles {
            for profile in profiles {
                guard !shownProfiles.contains(where: { $0.id == profile.id }) else {
                    return
                }
                shownProfiles.append(profile)
            }
            dep.defaultsManager.saveTwoDailyProfiles(profiles)
            scheduleStoredDailyTimer()
        }
    }
    
    func functionCaller() {
        if let endTime = dep.defaultsManager.getDailyProfileTimerEnd() {
            let timeRemaining = endTime.timeIntervalSinceNow

            if timeRemaining <= 300 {
                guard shownProfiles.count < 4 else { return }
                Task {
                    await createTwoDailyProfiles()
                }
            }
        } else {
            Task { await deleteTwoDailyProfiles()}
        }
    }
    
    func deleteTwoDailyProfiles() async {
        let ids = dep.defaultsManager.getTwoDailyProfiles()
        shownProfiles.removeAll(where: { ids.contains($0.id) })
        dep.defaultsManager.deleteTwoDailyProfiles()
    }
    
    private func scheduleStoredDailyTimer() {
        if let endDate = dep.defaultsManager.getDailyProfileTimerEnd() {
            scheduleDailyTimer(for: endDate)
        }
    }
    
    private func scheduleDailyTimer(for endDate: Date) {
        profileTimerTask?.cancel()
        let interval = endDate.timeIntervalSinceNow
        if interval <= 0 {
            Task { await timerFired() }
        } else {
            profileTimerTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                await self?.timerFired()
            }
        }
    }
    
    private func timerFired() async {
        dep.defaultsManager.clearDailyProfileTimer()
        await deleteTwoDailyProfiles()
        await createTwoDailyProfiles()
    }
    
    func retrieveTwoDailyProfiles() {
        Task {
            let dailyProfiles  = try? await dep.defaultsManager.retrieveTwoDailyProfiles()
            if let dailyProfiles {
                shownProfiles.append(contentsOf: dailyProfiles)
            }
        }
    }
}
