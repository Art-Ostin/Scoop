//
//  InviteCardOverlays.swift
//  Scoop
//
//  Created by Art Ostin on 04/09/2026.
//

import SwiftUI

private let hPadding = Spacing.lg

//Main Overlay of the card
struct InviteCardOverlay: View {
        
    let draft: RespondDraft
    let name: String
    let openInvite: () -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(name)
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)
                .eventZoomTitleSource(name) //Flies into the respond card's "<name>'s Invite"
            
            //Both fly into the respond card's own rows, restyling on the way (`.eventZoomRowTarget`)
            lineSection(.whiteClock, timeText)
                .eventZoomTimeSource(timeText)
                .lineLimitAndShrink(1)
            
            lineSection(.whiteMap, placeText)
                .lineLimit(1)
                .eventZoomPlaceSource(placeText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, hPadding)
        .padding(.bottom, 28)
        .padding(.trailing, 48)
        .overlay(alignment: .topTrailing) { typeAndInfoButton}
        .overlay(alignment: .bottomTrailing) {inviteButton}
    }
}

extension InviteCardOverlay {
    private func lineSection(_ image: ImageResource, _ text: String) -> some View {
        HStack(spacing: 20) {
            Image(image)
                .scaleEffect(1.2)
                .frame(width: 20)
                .offset(y: -2)//Fine tuned so in centre
            
            Text(text)
                .font(.body(20, .medium))
                .foregroundStyle(Color.white)
        }
    }
    
    private var typeAndInfoButton: some View {
        Button {
            
        } label: {
            HStack(alignment: .center, spacing: Spacing.sm) {
                Text(typeText)
                    .font(.body(15))
            }
//            .scaleEffect(0.9)
            .foregroundStyle(Color.white)
            .frame(height: 25)
            .padding(.trailing, 7)
            .padding(.leading, 5) //Leading edge bit extra padding
//            .capsuleStroke(lineWidth: 1, color: .white.opacity(0.6))
            .padding(.top, 3.5)
            .padding(.trailing, hPadding)
            .expandHitArea()
        }
        .shrinkButton()
    }
    
    //Hoisted, so the drawn line and the one the flight is told about can never disagree

    
    private var inviteButton: some View {
        InviteButton(onTap: openInvite)
        .eventZoomButtonSource() //Widens into the respond card's CTA — inside the paddings, so it measures the circle itself
        .padding(.horizontal, hPadding)
        .padding(.bottom, 26) //28 + 4
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
    
    private var typeText: String {
        let originalType = draft.originalInvite.event.type
        let newEventType = draft.newEvent.type
        switch draft.respondType {
        case .newEvent:
            return newEventType.emoji + "  " + newEventType.longTitle
        default :
            return originalType.emoji + "  " + originalType.longTitle
        }
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

    private static var label: some View {
        Text("Response")
            .font(.body(12, .bold))
            .padding(.vertical, Spacing.xxs)
            .padding(.horizontal, Spacing.xs)
            .foregroundStyle(Color.textPrimary)
    }
}
