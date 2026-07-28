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
    
    //Injected Properties -> Highly specific so can use for 'RespondInvite' screen as well
    let name: String
    let type: Event.EventType
    let proposedTimes: ProposedTimes
    let place: EventLocation
    let message: String?
    
    @Binding var showConfirmScreen: Bool?
    @Binding var showMessageScreen: Bool

    //Local Properties
    @State private var scrollProgress: Double = 0
    @State private var showInfoSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            nameTitle
            scrollView
            WarningLabel()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) { InviteTypeButton(type: type, showInfoSheet: $showInfoSheet) }
        .padding(.top, 20)
        .sheet(isPresented: $showInfoSheet) {ConfirmInfoScreen(type: type).presentationDetents(detents: .init(small: .medium))}
    }
}


//Components
extension ConfirmInvitePage {
    
    private var nameTitle: some View {
        Text(name)
            .font(.title(24, .bold))
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, Spacing.margin)
    }
    
    
    
}

//ScrollView
extension ConfirmInvitePage {
    
    
    
    
    
    
    
    
    private var scrollView: some View {
        HorizontalScrollView(progress: $scrollProgress) {
            timePlaceTypeSection
                .fixedSize(horizontal: false, vertical: true)   // pin single-line rows to natural height
                .padding(.horizontal, Spacing.margin)
                .padding(.vertical, 28)                 // pure hit-area; won't scale the type
                .containerRelativeFrame(.horizontal, alignment: .leading)
                .padding(.top, 1) //Subtle visual alignment (as type icon overlay makes it slightly closer)
            
            messageSection
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
    }
}
