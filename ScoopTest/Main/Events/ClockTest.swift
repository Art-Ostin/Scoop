//
//  ClockTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct ClockTest: View {
    @State private var countdown = CountdownViewModel(dateKey: "dailyProfilesDate")
    
    var body: some View {
        countdownTimer
    }
}

#Preview {
    ClockTest()
}


extension ClockTest {
    
    
    private var countdownTimer: some View {
        HStack(spacing: 32) {
            clockSection(time: countdown.hourRemaining, sign: "hr")
            clockSection(time: countdown.minuteRemaining, sign: "m")
            clockSection(time: countdown.secondRemaining, sign: "s")
        }
        .foregroundStyle(.white)
        .frame(width: 253, height: 52)
        .background(Color.accent)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
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
}
