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

struct ConfirmContainer<TimeRow: View>: View {
    
    let event: InviteSummary
    let name: String
    let isCard: Bool
    let timeOpen: Bool
    
    @Binding var showMessageScreen: Bool
    
    @ViewBuilder var timeRow: TimeRow
    
    let showInfo: () -> ()
    let openInvite: () -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            InviteName(name: name, isCard: isCard)
            
            scrollView
            
            if !isCard {WarningLabel()}
        }
        .padding(.horizontal, isCard ? 24 : Spacing.margin)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) { overlayTypeButton}
        .overlay(alignment: .bottomTrailing) { if isCard { InviteButton {openInvite()} } }
        .padding(.top, isCard ? 0 : 20)
        .padding(.vertical, isCard ? 24 : 0)
        .padding(.bottom, isCard ? 5 : 0)
    }
    
    private var overlayTypeButton: some View {
        TypeButton(type: event.type, timeOpen: false, isCard: isCard) {
            showInfo()
        }
    }
    private var scrollView: some View {
        ConfirmScrollView(
            invite: event,
            timeOpen: timeOpen,
            isCard: isCard,
            showMessageScreen: $showMessageScreen,
            timeRow: {timeRow})
    }
}

struct ConfirmScrollView<TimeRow: View>: View {
    
    let invite: InviteSummary
    let timeOpen: Bool
    let isCard: Bool
    @Binding var showMessageScreen: Bool
    
    @ViewBuilder var timeRow: TimeRow
    
    @State var scrollProgress: Double = 0
    
    var body: some View {
        HorizontalScrollView(progress: $scrollProgress) {
            TimeAndPlaceRows(place: invite.place) {timeRow}
            
            if !isCard {messageScreen}
        }
        .overlay(alignment: .bottomTrailing) {pageIndicator}
        .scrollClipDisabled()
        .customHScrollFade()
        .padding(.horizontal, -Spacing.margin)
    }
    
    private var messageScreen: some View {
        ConfirmMessageSection(
            message: invite.message,
            showMessageScreen: $showMessageScreen
        )
    }
    
    private var pageIndicator: some View {
        return Group {
            if !isCard {
                InvitePageIndicator(count: 2, progress: scrollProgress)
            }
        }
    }
}

struct InviteName: View {
    let name: String
    let isCard: Bool

    var body: some View {
        Text(name)
            .font(.title(isCard ? 26 : 24, .bold))
            .foregroundStyle(isCard ? Color.white : Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}


struct WarningLabel: View {
    
    var body: some View {
        HStack(spacing: Spacing.md){
            Image("ConfirmIcon")
            
            Text("Not showing may result in a blocked account")
                .font(.body(14, .regular))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fillGray.opacity(0.5), in: .rect(cornerRadius: CornerRadius.sm))
        .padding(.horizontal, Spacing.margin)
    }
}

