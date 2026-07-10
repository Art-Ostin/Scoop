//
//  SettingsButton.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
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


//To disappear when it is not at the top.
private struct ScrollTopTracker: ViewModifier {
    @Binding var isAtTop: Bool
    @State private var expandedInset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentInsets.top } action: { _, inset in
                expandedInset = max(expandedInset, inset)
                isAtTop = inset >= expandedInset - 1
            }
            .onAppear {
                expandedInset = 0
                isAtTop = true
            }
    }
}

extension View {
    func trackTopOfScroll(_ isAtTop: Binding<Bool>) -> some View {
        modifier(ScrollTopTracker(isAtTop: isAtTop))
    }
}
