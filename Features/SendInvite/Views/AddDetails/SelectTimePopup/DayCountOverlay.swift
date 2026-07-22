//
//  DayWarningSign.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct DayCountAndWarning: View {
    
    
    @Namespace private var countNS
    
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
    }
}

extension DayCountAndWarning {
    
    private var dayCountDisplay: some View {
        Text("\(dayCount)/\(ProposedTimes.maxCount)")
            .contentTransition(.numericText(value: Double(dayCount)))
            .foregroundStyle(Color.textPrimary)
            .font(.body(12, .bold))
            .matchedGeometryEffect(id: "icon", in: countNS, properties: .position)
            .transition(
                .scale(scale: 0.4)
                .combined(with: .opacity)
            )
    }

    private var savedIcon: some View {
        SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: true)
            .matchedGeometryEffect(id: "icon", in: countNS, properties: .position)
            .opacityPop(visible: showSaved)
            .transition(
                .scale(scale: 0.4)
                .combined(with: .opacity)
            )
    }
    
    private func warningText(_ warning: String) -> some View {
        Text(warning)
            .font(.body(12, .bold))
            .foregroundStyle(Color.warningYellow)
            .matchedGeometryEffect(id: "icon", in: countNS, properties: .position)
            .transition(
                .scale(scale: 0.4)
                .combined(with: .opacity)
            )
    }
}


