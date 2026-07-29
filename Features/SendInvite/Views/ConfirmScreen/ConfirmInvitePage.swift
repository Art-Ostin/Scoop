//
//  ConfirmInviteScreen.swift
//  Scoop
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI

enum ConfirmMode {
    case Invite, Respond
}


struct ConfirmInvitePage: View {
    
    let event: InviteSummary
    let name: String
    
    let isConfirmInvite: Bool
    
    @Binding var showMessageScreen: Bool

    //Local Properties
    @State private var scrollProgress: Double = 0
    @State private var showInfoSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InviteName(name: name, isPopup: false)
            scrollView
            WarningLabel()
        }
        .padding(.horizontal, Spacing.margin)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) { InviteTypeButton(type: event.type, showInfoSheet: $showInfoSheet) }
        .padding(.top, 20)
        .sheet(isPresented: $showInfoSheet) {Text(event.type.title).presentationDetents([.medium])}
    }
}


//Components
extension ConfirmInvitePage {
    
    
    
    private var scrollView: some View {
        HorizontalScrollView(progress: $scrollProgress) {
            
            
            
            
            
            TimeAndPlaceSection(proposedTimes: event.time, place: event.place)
                    .fixedSize(horizontal: false, vertical: true)   // pin single-line rows to natural height
                    .padding(.horizontal, Spacing.margin)
                    .padding(.vertical, 28)                 // pure hit-area; won't scale the type
                    .containerRelativeFrame(.horizontal, alignment: .leading)
                    .padding(.top, 1)
            
            ConfirmMessageSection(message: event.message, showMessageScreen: $showMessageScreen)
                .padding(.horizontal, Spacing.margin)
                .containerRelativeFrame(.horizontal, alignment: .leading)
        }
        .overlay(alignment: .bottomTrailing) {
            InvitePageIndicator(count: 2, progress: scrollProgress)
                .padding(.trailing, Spacing.lg)
                .padding(.bottom, 18)
        }
        .scrollClipDisabled()
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: true, isCardInvite: true)
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: false, isCardInvite: true)
        .padding(.horizontal, -Spacing.margin)
    }
}
