//
//  ConfirmInviteScreen.swift
//  Scoop
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI


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
        .overlay(alignment: .topTrailing) { typeButton}   //Sits on the text block, not the card
        .foregroundStyle(isCard ? Color.white : Color.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: isCard ? CGFloat.infinity : nil, alignment: isCard ? .bottomLeading : .leading)
        .overlay(alignment: .bottomTrailing) { inviteButton }
        .padding(.top, isCard ? 0 : 20)
        .padding(.horizontal, Spacing.lg)
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
        TypeButton(type: event.type, timeOpen: timeOpen, isCard: isCard, showInfo: showInfo)
    }
    
    private var inviteButton: some View {
        Group {
            if isCard {
                if let openInvite {
                    InviteButton(onTap: openInvite)
                        .padding(.bottom, 24)
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
    
    @State private var scrollProgress: Double = 0
    
    var body: some View {
        HorizontalScrollView(progress: $scrollProgress) {
            TimeAndPlaceRows(place: invite.place, isCard: isCard, timeOpen: timeOpen) {timeRow}
            
            if !isCard {messageScreen}
        }
        .padding(.vertical, isCard ? 0 : 28)
        .overlay(alignment: .bottomTrailing) {pageIndicator}
        .scrollClipDisabled()
        .customHScrollFade(showFade: !isCard)
        .padding(.horizontal, -Spacing.margin)
        .scrollDisabled(isCard)
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
            Image(.inviteTick)
            
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
    }
}


/*
 .padding(.top, isCard ? 0 : 20)
 .padding(.bottom, isCard ? Spacing.lg + 5 : 0)   //Geometry: 5pt optical lift off the card edge
 .fixedSize(horizontal: false, vertical: isCard)   //Hug the rows on the card: the pager is vertically greedy and would eat the whole image

 */
