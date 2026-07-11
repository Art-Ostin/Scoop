//
//  ToolbarButtons.swift
//  Scoop Test
//
//  Created by Art Ostin on 11/07/2026.
//

import SwiftUI

struct InfoButton: View {
    @Binding var showScreen: Bool
    var isAtTopOfScroll: Bool = true
    
    var body: some View {
        Group {
            if isAtTopOfScroll {
                ScoopButton(shape: Circle(), size: .medium, action: {showScreen = true}) {
                    Image(systemName: "info.circle")
                        .font(.body(18, .medium))
                }
                .transition(.scoopPop)
                .padding(.top, Spacing.md) //As its small icon, sits in correct position
                .padding(.horizontal, Spacing.margin)
            }
        }
        .animation(.scoopPop, value: isAtTopOfScroll)
    }
}

//Created here as frozen & Blocked view need it
struct SettingsButton: View {
    let action: () -> ()
    var body: some View {
        ScoopButton(shape: Circle(), size: .medium, action: action) {
            Image(systemName: "gear")
                .font(.body(14, .medium))
        }
    }
}
