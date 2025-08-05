//
//  MainClockView.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import SwiftUI

struct LargeClockView: View {
    
    let targetTime: Date
    
    var body: some View {
        CountdownTimer(targetTime: targetTime) { timeremaining in
            HStack(spacing: 32) {
                clockSection(time: timeremaining.hour ?? 0, sign: "hr")
                clockSection(time: timeremaining.hour ?? 0, sign: "m")
                clockSection(time: timeremaining.hour ?? 0, sign: "s")
            }
        }
        .foregroundStyle(.white)
        .frame(width: 253, height: 52)
        .background(Color.accent)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
    }
    
    private func clockSection(time: Int, sign: String) -> some View {
        HStack(spacing: 5) {
            Text(String(format: "%02d", max(0, time)))
                .font(.custom("SFCompactRounded-Semibold", size: 28))
            Text(sign)
                .font(.custom("SFCompactRounded-Regular", size: 14))
                .offset(y: 5)
        }
    }
}




//#Preview {
//    MainClockView(targetTime: Date.da)
//}
