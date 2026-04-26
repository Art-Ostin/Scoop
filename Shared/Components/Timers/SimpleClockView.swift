//
//  SimpleClockView.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import SwiftUI

struct SimpleClockView: View {
    
    let targetTime: Date
    let onFinished: () -> Void
    let withSymbols: Bool
    
    init(targetTime: Date, onFinished: @escaping () -> Void, withSymbols: Bool = false) {
        self.targetTime = targetTime
        self.onFinished = onFinished
        self.withSymbols = withSymbols
    }
    
    var body: some View {
        CountdownTimer(targetTime: targetTime, onFinished: { onFinished() }) { timeRemaining in
            let h = timeRemaining.hour ?? 0
            let m = timeRemaining.minute ?? 0
            let s = timeRemaining.second ?? 0
            let timeString = String(format: "%02d : %02d : %02d", h, m, s)
            let timeString2 = String(format: "%02dhr %02dm %02ds", h, m, s)
            if withSymbols {
                Text(timeString)
            } else {
                Text(timeString2)
            }
        }
    }
}
