//
//  DayWarningSign.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct DayCountAndWarning: View {
    
        
    let showSaved: Bool
    let warning: DayWarning?
    let dayCount: Int
    
    var body: some View {
        ZStack {
            if showSaved {
                savedIcon
            } else if let warning {
                warningText(warning.rawValue)
            } else {
                dayCountDisplay
            }
        }
        .animation(.transition, value: dayCount)
        .animation(.transition, value: warning)
        .animation(.transition, value: showSaved)
    }
}

extension DayCountAndWarning {
    
    private var dayCountDisplay: some View {
        Text("\(dayCount)/\(ProposedTimes.maxCount)")
            .contentTransition(.numericText(value: Double(dayCount)))
            .foregroundStyle(Color.textPrimary)
            .font(.body(12, .bold))
            .transition(.blurReplace)
    }

    private var savedIcon: some View {
        SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: true)
            .transition(.blurReplace)
    }
    
    private func warningText(_ warning: String) -> some View {
        Text(warning)
            .font(.body(12, .bold))
            .foregroundStyle(Color.warningYellow)
            .transition(.blurReplace)
    }
}

