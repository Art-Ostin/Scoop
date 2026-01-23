//
//  MainClockView.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import SwiftUI

struct LargeClockView: View {
    
    let targetTime: Date
    let onFinished: () -> Void
    
    
    var body: some View {
        CountdownTimer(targetTime: targetTime, onFinished: {onFinished()}) { timeRemaining in
            let days = timeRemaining.day ?? 0
            let hours = timeRemaining.hour ?? 0
            let minutes = timeRemaining.minute ?? 0
            let seconds = timeRemaining.second ?? 0

            if days > 20 {
                HStack(spacing: 32) {
                    clockSection(time: days, sign: "days")
                    clockSection(time: hours, sign: "hr")
                    clockSection(time: minutes, sign: "m")
                }
            } else {
                HStack(spacing: 32) {
                    clockSection(time: hours, sign: "hr")
                    clockSection(time: minutes, sign: "m")
                    clockSection(time: seconds, sign: "s")
                }
            }
        }
        .foregroundStyle(.white)
        .frame(width: 253, height: 52)
        .background( Color.accent)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
    }
    func clockSection(time: Int, sign: String) -> some View {
        HStack(spacing: 5) {
            Text(String(format: "%02d", max(0, time)))
                .font(.custom("SFCompactRounded-Semibold", size: 28))
            Text(sign)
                .font(.custom("SFCompactRounded-Regular", size: 14))
                .offset(y: 5)
        }
    }
}
