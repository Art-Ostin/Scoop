//
//  ClockTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI
import Combine

struct CountdownTimer: View {
    
    let meetUpTime: Date
    
    @State private var hourRemaining = "00"
    @State private var minuteRemaining = "00"
    @State private var secondRemaining = "00"
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
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
        .onReceive(timer) { _ in updateTimeRemaining() }
        .onAppear { updateTimeRemaining() }
    }
    
    private func clockSection(time: String, sign: String) -> some View {
        HStack(spacing: 5) {
            Text(time)
                .font(.custom("SFCompactRounded-Semibold", size: 28))
            Text(sign)
                .font(.custom("SFCompactRounded-Regular", size: 14))
                .offset(y: 5)
        }
    }
    
    private func updateTimeRemaining() {
        let timeRemaining = Calendar.current.dateComponents([
            .hour,
            .minute,
            .second
        ], from: Date(), to: meetUpTime)

        let hour = max(0, timeRemaining.hour ?? 0)
        let minute = max(0, timeRemaining.minute ?? 0)
        let second = max(0, timeRemaining.second ?? 0)

        hourRemaining = String(format: "%02d", hour)
        minuteRemaining = String(format: "%02d", minute)
        secondRemaining = String(format: "%02d", second)
    }
}
