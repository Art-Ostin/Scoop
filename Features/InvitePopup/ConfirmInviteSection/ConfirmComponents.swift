//
//  ConfirmComponents.swift
//  Scoop
//
//  Created by Art Ostin on 30/07/2026.
//

import SwiftUI

//Contains Scroll View With Message Section as well
struct ConfirmTimeAndPlace<TimeRow: View>: View {

    //Injected
    let place: EventLocation
    let message: String?

    //Hide place row when time popup is open
    let timeOpen: Bool

    let style: ConfirmStyle

    //Can add a message in confirm message if they haven't already
    @Binding var showMessageScreen: Bool

    //Pass In the time view as time Row very different between sending and responding to an Invite
    @ViewBuilder var timeRow: TimeRow

    //Track scroll Progress for the page indicator
    @State private var scrollProgress: Double = 0

    var body: some View {
        //Top aligned: the short message page starts level with the time row, not centred against it
        HorizontalScrollView(progress: $scrollProgress, alignment: .top) {
            TimeAndPlaceRows(place: place, style: style, timeOpen: timeOpen) {timeRow}
            messageScreen
        }
        .overlay(alignment: .bottomTrailing) {if style.showScrollView { pageIndicator }}
        .padding(.top, style.timeAndPlaceTopPadding)
        .scrollClipDisabled()
        .padding(.horizontal, -Spacing.margin) //So scroll view goes to the edges
        .scrollDisabled(!style.showScrollView)
    }
    
    private var messageScreen: some View {
        ConfirmMessageSection(
            message: message,
            showMessageScreen: $showMessageScreen, isConfirmSend: style == .respondPopup
        )
    }
    
    private var pageIndicator: some View {
        InvitePageIndicator(count: 2, progress: scrollProgress)
            .padding(.trailing, Spacing.lg)
            .offset(y: -22) //The Time and Place rows apply 26 vertical padding. This is to offset that so only 4points below that view
    }
}

struct TypeButton: View {

    //Injected
    let type: Event.EventType
    let timeOpen: Bool
    let showInfo: () -> ()

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.xxs) {
            Text(type.emoji)
                .font(.body(15))

            Text(type.longTitle)
                .font(.body(15, .bold))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .stroke(CornerRadius.sm, color: Color.white.opacity(0.6))
        .shrinkPress(action: showInfo)
        .offset(y: 1.5)
        .scaleEffect(0.8, anchor: .bottomTrailing)
        .opacityPop(visible: !timeOpen)
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

struct InviteInfoButton: View {
    let showInfo: () -> ()
    
    var body: some View {
        Image(systemName: "info.circle")
            .font(.body(12, .medium))
            .foregroundStyle(Color.textSecondary)
            .frame(width: 28, height: 28)
            .background(Color.fillGray.opacity(0.5), in: Circle())
            .shrinkPress {showInfo() }
            .padding()
            .padding(.top, -6)
    }
}


