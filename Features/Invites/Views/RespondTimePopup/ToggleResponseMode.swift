//
//  ToggleButton.swift
//  Scoop Test
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
                .font(.body(10, .medium))
            
            Text("Options")
        }
        .foregroundStyle(Color.textSecondary)
        .font(.body(12, .medium))
    }

        
        
    
    private var cantMakeItLabel: some View {
        Text("Can't make it?")
            .font(.body(12, .bold))
            .foregroundStyle((Color.textSecondary))
            .kerning(0.5)
    }
    
    private func switchView() {
        togglePage()
        if timePopupPage == .newTime { //Only switch the type to modified, if I have modified selected
            if anyNewProposedTimes { responseType = .modified }
        } else {//Only switches if there are available dates
            if anyAvailableInvitedDays { responseType = .original}
        }
    }
    
    private func togglePage() {
        timePopupPage = timePopupPage == .newTime
        ? .invitedTimes
        : .newTime
    }
}
