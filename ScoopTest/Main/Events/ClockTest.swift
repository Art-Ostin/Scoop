//
//  ClockTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI
import Combine


@Observable class countdownViewModel {
    
    
    
    
    
    
}


struct countdownTimer: View {
    
    
    let meetUpTime: Date?
    var cancellables = Set<AnyCancellable>()
    
    var hourRemaining = ""
    var minuteRemaining = ""
    var secondRemaining = ""
    
    
    var body: some View {
        
        HStack(spacing: 32) {
            clockSection(time: hourRemaining, sign: "hr")
            clockSection(time: minuteRemaining, sign: "m")
            clockSection(time: secondRemaining, sign: "s")
        }
        .foregroundStyle(.white)
        .frame(width: 253, height: 52)
        .background(Color.accent)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
        
        
    }
    func clockSection(time: String, sign: String) -> some View {
        HStack(spacing: 5) {
            Text(time)
                .font(.custom("SFCompactRounded-Semibold", size: 28))
            Text(sign)
                .font(.custom("SFCompactRounded-Regular", size: 14))
                .offset(y: 5)
        }
    }
    
    mutating func starTimer() {
        Timer
            .publish(every: 1.0, on: .main, in: .common).autoconnect()
            .sink {_ in updateTimeRemaining()}
            .store(in: &cancellables)
    }
    
    mutating func updateTimeRemaining() {
        guard let meetUpTime = meetUpTime else { return }
        
        let timeRemaining = Calendar.current.dateComponents([.hour, .minute, .second], from: Date(), to: meetUpTime)
        let hour = max(0, timeRemaining.hour ?? 0)
        let minute = max(0, timeRemaining.minute ?? 0)
        let second = max(0, timeRemaining.second ?? 0)
        hourRemaining = String(format: "%02d", hour)
        minuteRemaining = String(format: "%02d", minute)
        secondRemaining = String(format: "%02d", second)
    }
}
