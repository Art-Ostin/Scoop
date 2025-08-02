//
//  NewCountdownViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 01/08/2025.
//

import Foundation
import Combine

@Observable


class CountdownViewModel {
    
    
    var defaults: UserDefaults
    var dateKey: String
    
    init(defaults: UserDefaults = .standard, dateKey: String) {
        self.defaults = defaults
        self.dateKey = dateKey
        starTimer()
        updateTimeRemaining()
    }
    
    var hourRemaining = ""
    var minuteRemaining = ""
    var secondRemaining = ""
    
    var timeUp: Bool {
        if hourRemaining == "00" && minuteRemaining == "00" && secondRemaining == "00" { return true }
        return false
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func starTimer() {
        Timer
            .publish(every: 1.0, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.updateTimeRemaining()}
            .store(in: &cancellables)
    }
    
    func updateTimeRemaining() {
        let startTime = defaults.object(forKey: dateKey) as? Date ?? Date()
        let targetTime = Calendar.current.date(byAdding: .minute, value: 5, to: startTime) ?? Date()
        let timeRemaining = Calendar.current.dateComponents([.hour, .minute, .second], from: Date(), to: targetTime)
        
        let hour = max(0, timeRemaining.hour ?? 0)
        let minute = max(0, timeRemaining.minute ?? 0)
        let second = max(0, timeRemaining.second ?? 0)
        hourRemaining = String(format: "%02d", hour)
        minuteRemaining = String(format: "%02d", minute)
        secondRemaining = String(format: "%02d", second)
    }
}
