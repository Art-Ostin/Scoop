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
    let showMessageSection: Bool

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
        HorizontalScrollView(progress: $scrollProgress, alignment: .top) {
            TimeAndPlaceRows(place: place, style: style, timeOpen: timeOpen) {timeRow}
            messageScreen
        }
        .overlay(alignment: .bottomTrailing) {if style.showScrollView { pageIndicator }}
        .padding(.top, style.timeAndPlaceTopPadding)
        .scrollClipDisabled()
        .customHScrollFade(showFade: style.showScrollView) //Don't show fade if its on card
        .padding(.horizontal, -Spacing.margin) //So scroll view goes to the edges
        .scrollDisabled(!style.showScrollView)
    }
    
    @ViewBuilder
    private var messageScreen: some View {
        if showMessageSection {
            ConfirmMessageSection(
                message: message,
                showMessageScreen: $showMessageScreen, isConfirmSend: style == .respondPopup
            )
        }
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
                .font(.body(13))

            Text(type.longTitle)
                .font(.body(13, .bold))
        }
        .foregroundStyle(Color.white)
        .frame(height: 25)
        .padding(.trailing, 8)
        .padding(.leading, 6) //Leading edge bit extra padding
        .capsuleStroke(lineWidth: 1, color: .white)
        .shrinkPress(action: showInfo)
        .opacityPop(visible: !timeOpen)
        .offset(y: 4.5)
    }
}

struct WarningLabel: View {
    
    var body: some View {
        HStack(spacing: 10) {
            Image(.triangleWarning)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(Color.accent)
            
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


