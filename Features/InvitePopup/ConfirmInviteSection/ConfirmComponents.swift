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
            .offset(x: -6)
    }
}

struct TypeButton: View {

    //Injected
    let type: Event.EventType
    let timeOpen: Bool
    let showInfo: () -> ()

    var body: some View {
        //A Button, never `.shrinkPress` — the chip rides the invite pager, and a zero-distance
        //DragGesture there swallows the pan (see PlaceRow).
        Button(action: showInfo) {
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
        }
        .shrinkButton()
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
        .frame(height: 35)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fillGray, in: .rect(cornerRadius: CornerRadius.sm))
    }
}

struct InviteInfoButton: View {
    let showInfo: () -> ()

    var body: some View {
        Image(systemName: "info.circle")
            .font(.body(12, .medium))
            .foregroundStyle(Color.textSecondary)
            .frame(width: 28, height: 28)
            .background { glassDisc }
            .shrinkPress {showInfo() }
            .padding()
            .padding(.top, -6)
    }

    //Glass casts a drop shadow no API can switch off, and at disc size over the card's
    //near-white body `.regular` reads as a grey halo. THE CLIP IS LOAD-BEARING — it crops the
    //spill outside the circle. Sim-measured on iOS 26.0 (mean luminance in annuli outside the
    //28pt edge, against a no-shadow `.ultraThinMaterial` control):
    //      unclipped −2.5% / −2.3% / −1.6% · this −0.9% / −0.8% / −0.6% · control −0.9% / −0.8% / −0.6%
    //Drawn on its own background layer, not on the content, so the clip can't take the glyph
    //with it. (`.clear` is shadowless even unclipped, but blows to pure white on a body this
    //light — nothing behind it to refract.)
    @ViewBuilder
    private var glassDisc: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: Circle())
                .clipShape(Circle())
        } else {
            Circle().fill(Color.fillGray)
        }
    }
}

struct AddNoteButton: View {
    
    @Binding var showInfoScreen: Bool
    
    var body: some View {
        Text("Add a Note")
            .frame(width: 82, height: 22)
            .capsuleStroke(lineWidth: 1, color: .accent)
            .shrinkPress { showInfoScreen = true }
    }
}


/*
 .background(Color.fillGray, in: Circle())

 */
