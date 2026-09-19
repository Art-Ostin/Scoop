//
//  InviteCardOverlays.swift
//  Scoop
//
//  Created by Art Ostin on 04/09/2026.
//

import SwiftUI

private let hPadding = Spacing.lg
private let rowSize = EventZoomRowMorph.sourceSize //The row flight's source type, so the card and its flying copy can't disagree
private let rowGap = Spacing.md //Tighter than the name's gap, so the rows read as one block under it
private let footInset = Spacing.lg - 0.215 * rowSize //Geometry: ModernEra's baseline sits 0.215em over its line box's foot, so dropping the box that far lands the last baseline Spacing.lg off the card's foot, level with the sides
private let buttonReserve: CGFloat = 42 + Spacing.xs //Geometry: InviteButton's circle, plus the gap the words keep from it

//Main Overlay of the card
struct InviteCardOverlay: View {

    let draft: RespondDraft
    let name: String
    let openInvite: () -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                Text(name)
                    .font(.title(26, .bold))
                    .foregroundStyle(Color.white)
                    .eventZoomTitleSource(name) //Flies into the respond card's "<name>'s Invite"
                    .frame(maxWidth: .infinity, alignment: .leading) //Takes what the type leaves, so the two can't overlap

                typeLabel
            }

            //Both fly into the respond card's own rows, restyling on the way (`.eventZoomRowTarget`)
            VStack(alignment: .leading, spacing: rowGap) {
                lineSection(.whiteClock, timeText)
                    .eventZoomTimeSource(timeText)
                    .lineLimitAndShrink(1)
                    .offset(y: -4)//Do Not Remove!! CRitical Keep, paramount for design. 

                lineSection(.whiteMap, placeText)
                    .lineLimit(1)
                    .eventZoomPlaceSource(placeText)
            }
            .padding(.trailing, buttonReserve) //Only the rows run beside the envelope
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, hPadding)
        .padding(.bottom, footInset)
        .overlay(alignment: .bottomTrailing) { inviteButton }
    }
}

extension InviteCardOverlay {

    //The plan's type on the name's line, its trailing edge on the envelope's
    private var typeLabel: some View {
        HStack(spacing: Spacing.xs) {
            Text(eventType.emoji)
            Text(eventType.longTitle)
        }
        .font(.body(15))
        .foregroundStyle(Color.white)
        .fixedSize() //Never truncates; the name gives way
    }

    //The row flight's geometry: its source copy draws this same column, gap, glyph scale and type
    private func lineSection(_ image: ImageResource, _ text: String) -> some View {
        HStack(spacing: EventZoomRowMorph.sourceIconGap) {
            Image(image)
                .scaleEffect(EventZoomRowMorph.sourceIconScale)
                .frame(width: EventZoomRowMorph.iconWidth)
                .offset(y: -2) //Geometry: centres the glyph on the capitals — the nudge the flight releases as it lands

            Text(text)
                .font(.body(rowSize, .medium))
                .foregroundStyle(Color.white)
        }
    }

    private var inviteButton: some View {
        InviteButton(onTap: openInvite)
            .eventZoomButtonSource() //Widens into the respond card's CTA — inside the paddings, so it measures the circle itself
            .padding(.horizontal, hPadding)
            .padding(.bottom, Spacing.lg) //Its foot on the last baseline, as the Meet card's stands on its last line: a 24/24 corner, and about centred on the two rows
    }
}

//What gets shown on the card depends on what sort of invite it is
extension InviteCardOverlay {
    
    private var placeText: String {
        switch draft.respondType {
        case .newEvent: draft.newEvent.place?.name ?? "Unknown"
        default: draft.originalInvite.event.location.name ?? "Unknown"
        }
    }
    
    
    private var timeText: String {
        switch draft.respondType {
        //Scenario 1: In Original Invite
        case .originalInvite:
            //First try and get the first selected date
            if let date = draft.originalInvite.selectedDay {
                return FormatEvent.shortDayAndTime(date)
                
                //That failing, get the first available Date
            } else if let date = draft.originalInvite.event.proposedTimes.firstAvailableDate {
                return FormatEvent.shortDayAndTime(date)
                //It should not be of type original Invite if no availble dates (should have updated) so
            } else {
                return " "
            }
            
        case .newTime:
            let proposedTimes = draft.newTime.proposedTimes
            //If there are any available times list those
            if !proposedTimes.dates.isEmpty {
                if let time = proposedTimes.dates.first {
                    return FormatEvent.shortDayAndTime(time.date)
                } else {
                    return ""
                }
            }
            //If no available Times use last originalInvite Time
            else {
                if let lastDay =  draft.originalInvite.event.proposedTimes.dates.last {
                    return FormatEvent.shortDayAndTime(lastDay.date)
                } else {
                    //That should always exist, if not just for whatever reason have this
                    return "Time Expired"
                }
            }
            
        case .newEvent:
            let proposedTimes = draft.newEvent.time.dates
            //If there are proposedTimes do this
            
            if !proposedTimes.isEmpty {
                if let time = proposedTimes.first {
                   return FormatEvent.shortDayAndTime(time.date)
                } else {
                    return ""
                }
            } else {
                //If there are no proposedTimes get them if there are any in the proposedInvites
                return "Time not Chosen"
            }
        }
    }
    
    private var eventType: Event.EventType {
        if case .newEvent = draft.respondType { return draft.newEvent.type }
        return draft.originalInvite.event.type
    }
}




//The 'Response' capsule: the invite's history, from the card's top-trailing corner
struct InviteHistoryButton: View {

    //Injected
    let action: () -> Void
    @Environment(\.eventZoomCornerSource) private var role //Live on the card; inert, or a bare slot, in the event zoom's flying chrome copy

    var body: some View {
        switch role {
        case .live:
            ScoopButton(style: Self.style, shape: .capsule, action: action) { Self.label }
                .buttonStyle(.automatic) //Its own press, not the card's: it sits inside the card's zoom Button, whose style would reach it
        case .inert:
            Self.capsule
        case .ghost:
            Self.label.hidden()
        }
    }

    //One style for both forms, so the capsule the corner hero flies can never drift from the button it takes off from
    private static let style: ScoopButtonStyle = .clearGlass

    ///ScoopButton's glass path without the Button: the flying copy, and what the corner hero takes off as
    static var capsule: some View {
        label
            .scoopGlassSurface(clear: Self.style == .clearGlass, shape: Capsule())
            .glassFallbackRestingShadow() //See EventBackButton.surface
    }

    private static let fontSize: CGFloat = 12
    static let height = fontSize + 2 * Spacing.xxs //Geometry: ModernEra's line box is its point size — what the card seats concentrically in its corner

    private static var label: some View {
        Text("Response")
            .font(.body(fontSize, .bold))
            .padding(.vertical, Spacing.xxs)
            .padding(.horizontal, Spacing.xs)
            .foregroundStyle(Color.textPrimary)
    }
}
