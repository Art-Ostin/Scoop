//
//  OptionsMenu.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/07/2026.
//

import SwiftUI

struct OptionsMenu: View {
    
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
            optionsButton
        }
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
    
    private var optionsButton: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), size: .small) {
            
        } label: {
            optionsLabel
        }
    }

    //The Options Label
    private var optionsLabel: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in circle }
        }
        .scaleEffect(0.9)
        .contentShape(Circle())
    }

    private var circle: some View {
        Circle()
            .fill(.white.opacity(0.8))
            .frame(width: 4.5, height: 4.5)
    }
}



struct ChangeButton: View {
    
    @Binding var responseType: ResponseType
    @Binding var showConfirmScreen: Bool?
    
    var isNewEvent: Bool { responseType == .newEvent }
    var buttonText: String { isNewEvent ? "Original Invite" : "New Invite" }
    
    var body: some View {
        
        ScoopButton(style: .clearGlass, shape: .capsule) {
            if responseType != .newEvent {
                responseType = .newEvent
            } else {
                responseType = .originalInvite
            }
            showConfirmScreen = false
        } label: {
            HStack(spacing: 4) {
                if !isNewEvent {
                    Image(systemName: "plus")
                        .font(.body(12, .bold))
                }
                
                Text(buttonText)
                    .font(.body(11, .bold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .foregroundStyle(Color.white)
        }
    }
}

/*
 .padding(-Spacing.sm)
 */
