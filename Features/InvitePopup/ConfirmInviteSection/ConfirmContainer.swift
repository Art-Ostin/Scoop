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
    var openInvite: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InviteName(name: name, isCard: isCard)
                .opacityPop(visible: !timeOpen)
            
            scrollView
            
            if !isCard {WarningLabel()}
        }
        .frame(maxWidth: .infinity, maxHeight: isCard ? CGFloat.infinity : nil, alignment: isCard ? .bottomLeading : .leading)
        .overlay(alignment: .topTrailing) { typeButton}
        .overlay(alignment: .bottomTrailing) { inviteButton }
        .padding(.top, isCard ? Spacing.lg : 20)
        .padding(.bottom, isCard ? Spacing.lg + 5 : 0)   //Geometry: 5pt optical lift off the card edge
    }
    
    private var scrollView: some View {
        ConfirmScrollView(
            invite: event,
            timeOpen: timeOpen,
            isCard: isCard,
            showMessageScreen: $showMessageScreen,
            timeRow: {timeRow})
    }
    
    private var typeButton: some View {
        TypeButton(type: event.type, timeOpen: timeOpen, isCard: isCard) {
            showInfo()
        }
    }
    
    private var inviteButton: some View {
        Group {
            if isCard {
                if let openInvite {
                    InviteButton { openInvite() }
                }
            }
        }
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
            TimeAndPlaceRows(place: invite.place, timeOpen: timeOpen) {timeRow}
            
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

