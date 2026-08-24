//
//  DayCountOverlay.swift
//  Scoop
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
        .fixedSize() //A trailing accessory never truncates; the title column yields instead
        .animation(.transition, value: dayCount)
        .animation(.transition, value: warning)
        .animation(.transition, value: showSaved)
    }
}

extension DayCountAndWarning {
    
    //A glanceable counter, one level under the title. (No .monospacedDigit(): ModernEra renders it as a truncated glyph.)
    private var dayCountDisplay: some View {
        Text("\(dayCount)/\(ProposedTimes.maxCount)")
            .contentTransition(.numericText(value: Double(dayCount)))
            .foregroundStyle(Color.textSecondary)
            .font(.body(13, .medium))
            .transition(.blurReplace)
    }

    private var savedIcon: some View {
        SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: true)
            .transition(.blurReplace)
    }
    
    //Bold is reserved for the refusal, so it lands by contrast with the counter it replaces.
    private func warningText(_ warning: String) -> some View {
        Text(warning)
            .font(.body(13, .bold))
            .foregroundStyle(Color.warningYellow)
            .transition(.blurReplace)
    }
}
