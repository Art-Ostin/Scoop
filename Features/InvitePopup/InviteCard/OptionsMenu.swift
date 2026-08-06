//
//  OptionsMenu.swift
//  Scoop
//
//  Created by Art Ostin on 28/07/2026.
//

import SwiftUI

struct OptionsMenu: View {

    let hasChanges: Bool
    let onInfo: () -> Void
    let onClear: () -> Void
    let onDecline: () -> Void

    var body: some View {
        Menu {
            Button("How Invites Work", systemImage: "info.circle", action: onInfo)

            if hasChanges {
                Button(action: onClear) { Label("Clear Invite Draft", image: "BinIcon") }
            }

            Button(role: .destructive, action: onDecline) {
                Label("Decline Profile", systemImage: "xmark")
            }
        } label: {
            dotsLabel
        }
    }
}

extension OptionsMenu {

    private var dotsLabel: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { _ in
                Circle().frame(width: 4, height: 4)
            }
        }
        .foregroundStyle(.white.opacity(0.8))
        .buttonSize(.small)
        .scoopGlassSurface(clear: true, shape: .circle)
        .expandHitArea()
    }
}



struct ChangeButton: View {

    @Binding var responseType: ResponseType
    @Binding var showConfirmScreen: Bool?

    private var isNewEvent: Bool { responseType == .newEvent }

    var body: some View {
        ScoopButton(style: .clearGlass, shape: .capsule) {
            responseType = isNewEvent ? .originalInvite : .newEvent
            showConfirmScreen = false
        } label: {
            HStack(spacing: Spacing.xxs) {
                if !isNewEvent {
                    Image(systemName: "plus")
                        .font(.body(12, .bold))
                }

                Text(isNewEvent ? "Original Invite" : "New Invite")
                    .font(.body(11, .bold))
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 7)
            .foregroundStyle(Color.white)
        }
    }
}
