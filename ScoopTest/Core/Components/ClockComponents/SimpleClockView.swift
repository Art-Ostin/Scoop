//
//  SimpleClockView.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import SwiftUI

struct SimpleClockView: View {
    
    let targetTime: Date

    var body: some View {
        CountdownTimer(targetTime: targetTime) { timeRemaining in
            let h = timeRemaining.hour ?? 0
            let m = timeRemaining.minute ?? 0
            let s = timeRemaining.second ?? 0
            let timeString = String(format: "%02d:%02d:%02d", h, m, s)
            Text(timeString)
                .font(.body(16))
        }
    }
}

//#Preview {
//    SimpleClockView()
//}
