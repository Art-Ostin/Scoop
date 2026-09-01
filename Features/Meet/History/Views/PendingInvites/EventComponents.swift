//
//  EventComponents.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

//So all icons take up as much space as each other
private let iconWidth: CGFloat = 20

//Space between the Icon and the Text
private let iconGap: CGFloat = 20

//Total width until text so divider starts with text
private let textColumn = iconWidth + iconGap


struct EventImagePager: View {
    //Injected
    let title: String
    let images: [UIImage]

    @Environment(PendingFlightChoreo.self) private var flight: PendingFlightChoreo?

    private var isSettled: Bool { flight?.settled ?? true }

    var body: some View {
        Color.clear
            .aspectRatio(AspectRatio.pendingEvent.ratio, contentMode: .fit)
            .overlay {
                if isSettled {
                    inviteCarousel
                        .overlay(alignment: .bottomLeading) { profileName }
                        .scrollDisabled(flight?.dragEngaged ?? false) //An engaged dismiss drag freezes the pager's own axis
                }
            }
            //The cover's landing band: the flight morphs the tapped lens' photo into this rect
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight?.reportPagerBand($0) }
    }

    private var inviteCarousel: some View {
        InviteCarousel(
            images: images,
            ratio: AspectRatio.pendingEvent.ratio,
            blursBottom: true,
            scrollProgress: .constant(0))
    }
    
    private var profileName: some View {
        Text(title)
            .font(.title(22)) //The invite card's title type — "Invite <name>" reads the same here
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .padding(.horizontal, 20) //Geometry: the invite card's own title inset from the artwork edge
            .padding(.bottom, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EventTypeTimeAndPlace: View {
    
    let type: Event.EventType
    let message: String?
    let time: ProposedTimes
    let place: EventLocation
    
    var rowHeight: CGFloat = 33
    var lineSpacing: CGFloat = 19 //Fine tuned default
    var topPadding: CGFloat = 20
    var bottomPadding: CGFloat = Spacing.lg
    
    let openInfo: () -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            EventTypeRow(type: type, message: message, openEventInfo: { openInfo()})
            eventDivider
            EventTimeRow(time: time)
            eventDivider
            EventPlaceRow(location: place)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }
    
    //Divider between each row
    private var eventDivider: some View {
        VeryLightDivider()
            .padding(.leading, textColumn)
    }
}

struct EventTypeRow: View {
    
    let type: Event.EventType
    let message: String?
    
    var rowHeight: CGFloat = 33
    
    let openEventInfo: () -> ()
    
    var body: some View {
        HStack(spacing: iconGap) {
            Text(type.emoji)
                .font(.body(16, .bold))
                .frame(width: iconWidth)

            VStack(alignment: .leading, spacing: 6) {
                eventTypeAndInfoIcon
                
                if let message {
                    text(eventMessage: message)
                }
            }
        }
        .frame(minHeight: rowHeight) //Grows past the one-line row box when a message is present
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var eventTypeAndInfoIcon: some View {
        Button {
            openEventInfo()
        } label: {
            HStack(alignment: .top, spacing: 4) {
                Text(type.longTitle)
                    .font(.body(16, .bold))
                
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.textTertiary)
                    .font(.body(11, .medium))
                    .offset(y: -2)
            }
        }
        .growButton()
    }
    
    private func text(eventMessage: String) -> some View {
        Text(eventMessage)
            .font(.body(14, .regularItalic))
            .foregroundStyle(Color.textSecondary.opacity(0.7)) //Tad lighter than normal secondary
            .lineLimitAndShrink(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct EventTimeRow: View {
    
    var rowHeight: CGFloat = 33
    
    let time: ProposedTimes
    
    var body: some View {
        HStack(spacing: iconGap) {
            Image(.eventClockIcon)
                .scaleEffect(1.2)
                .frame(width: iconWidth)

            Text(time.formatMultipleInvitedDays())
                .font(.body(16, .bold))
        }
        .frame(height: rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EventPlaceRow: View {
    
    let location: EventLocation
    
    var rowHeight: CGFloat = 33
    
    var body: some View {
        HStack(spacing: iconGap) {
            Image(.eventMapIcon)
                .scaleEffect(1.2)
                .frame(width: iconWidth)

            Text(location.name ?? "View Venue")
                .font(.body(16, .bold))
        }
        .frame(height: rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension EventProfile {
    ///"Invited <name>" — the card's title, and the flight cover's clone of it. ONE source: the
    ///landing crossfades between the two, so they have to render the same glyphs
    var inviteTitle: String { "Invited \(profile.name)" }
}
