//
//  OptionsMenu.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/07/2026.
//

import SwiftUI

struct OptionsMenu: View {
    
    let showOptions: Bool
    let hasChanges: Bool
    
    @Binding var optionsFrame: CGRect

    let onDecline: () -> ()
    let deleteDraft: () -> ()
    let onInfo: () -> ()
    
    var body: some View {
        Menu {
            infoButton
            if hasChanges { clearInviteButton}
            declineButton
        } label: {
            optionsLabel
        }
        .opacityPop(visible: !showOptions)
        .padding(-Spacing.sm)
    }
}

extension OptionsMenu {

    //The Three button Rows
    private var infoButton: some View {
        Button("How Invites Work", systemImage: "info.circle") {
            onInfo()
        }
    }

    private var clearInviteButton: some View {
        Button {
            withAnimation(.transition) {
                deleteDraft()
            }
        } label: {
            Label {
                Text("Clear Invite Draft")
            } icon: {
                Image("BinIcon")
                    .renderingMode(.template)
                    .scaleEffect(1.2)
            }
        }
    }

    private var declineButton: some View {
        Button(role: .destructive) {
            onDecline()
        } label: {
            Label {
                Text("Decline Profile")
            } icon: {
                Image(systemName: "xmark")
                    .font(.body(14, .bold))
            }
        }
    }

    //The Options Label
    private var optionsLabel: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in circle }
        }
        .scaleEffect(0.95)
        .padding(2)
        .background {
            Capsule()
                .fill(Color.black.opacity(0.04))
                .blur(radius: 2)
        }
        .getRect($optionsFrame, coordSpace: "InviteImageCarousel")
        .padding(Spacing.sm - 2)//Offset interior padding with capsule
        .contentShape(Circle())
        .offset(y: -2)
    }

    private var circle: some View {
        Circle()
            .fill(.white.opacity(0.8))
            .frame(width: 4.5, height: 4.5)
    }
}
