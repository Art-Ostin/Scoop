//
//  CountdownToDate.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import Foundation
import Combine


@Observable class CountdownToDate {
    
    
    
    var hourRemaining = ""
    var minuteRemaining = ""
    var secondRemaining = ""

    
    private var cancellables = Set<AnyCancellable>()
    
    func starTimer(MeetUpDate: Date) {
        Timer
            .publish(every: 1.0, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.updateTimeRemaining(MeetUpDate: MeetUpDate)}
            .store(in: &cancellables)
    }
    
    func updateTimeRemaining(MeetUpDate: Date) {
        let timeRemaining = Calendar.current.dateComponents([.hour, .minute, .second], from: Date(), to: MeetUpDate)
        
        let hour = max(0, timeRemaining.hour ?? 0)
        let minute = max(0, timeRemaining.minute ?? 0)
        let second = max(0, timeRemaining.second ?? 0)
        hourRemaining = String(format: "%02d", hour)
        minuteRemaining = String(format: "%02d", minute)
        secondRemaining = String(format: "%02d", second)
    }

}


