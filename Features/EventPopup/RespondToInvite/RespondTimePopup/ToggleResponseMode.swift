//
//  ToggleResponseMode.swift
//  Scoop
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct ToggleResponseMode: View {
    
    //Update the invite response type when changed
    @Binding var responseType: ResponseType
    @Binding var timePopupPage: TimePopupPage?
    
    //Do not update to 'modified response type' when changing if no proposedTimes
    var anyNewProposedTimes: Bool
    var anyAvailableInvitedDays: Bool
    
    var body: some View {
        ZStack {
            if timePopupPage == .newTime {
                optionsLabel
                    .transition(.blurReplace)
            } else {
                cantMakeItLabel
                    .transition(.blurReplace)
            }
        }
        .animation(.transition, value: timePopupPage)
        .shrinkPress {
            switchView()
        }
    }
}

extension ToggleResponseMode {
    
    private var optionsLabel: some View {
        HStack(spacing: Spacing.hairline) {
            Image(systemName: "chevron.left")
                .font(.body(11, .medium))
            
            Text("Options")
        }
        .foregroundStyle(Color.textSecondary)
        .font(.body(13, .medium))
    }
    
    @ViewBuilder
    private var cantMakeItLabel: some View {
        if anyAvailableInvitedDays {
            Text("Can't make it?")
                .font(.body(13, .bold))
                .foregroundStyle((Color.textSecondary))
                .kerning(0.5)
        } else {
            HStack(spacing: Spacing.hairline) {
                Text("Choose Time")
                    .foregroundStyle(Color.textSecondary)
                    .font(.body(13, .medium))

                Image(systemName: "chevron.right")
                    .font(.body(11, .medium))
            }
        }
    }
    
    private func switchView() {
        togglePage()
        if timePopupPage == .newTime { //Only switch the type to modified, if I have modified selected
            if anyNewProposedTimes { responseType = .newTime }
        } else {
            if anyAvailableInvitedDays { responseType = .originalInvite}
        }
    }
    
    private func togglePage() {
        timePopupPage = timePopupPage == .newTime
        ? .invitedTimes
        : .newTime
    }
}
