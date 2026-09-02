//
//  TypeAndPlaceRow.swift
//  Scoop Test
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI


//MARK: Variable frequently used
//So all icons take up as much space as each other
private let iconWidth: CGFloat = 20

//Space between the Icon and the Text
private let iconGap: CGFloat = 20

//Total width until text so divider starts with text
private let textColumn = iconWidth + iconGap

//Row Height
private let rowHeight: CGFloat = 33

struct EventTypeTimeAndPlace<TimeRow: View>: View {
    //Injected Values
    let type: Event.EventType
    let message: String?
    let place: EventLocation
    let isViewOnly: Bool
    
    //Inject time as sometimes the row needs a binding
    let timeRow: TimeRow
    let openInfo: () -> ()
    
    //Padding depends on the version
    var lineSpacing: CGFloat { isViewOnly ? 19 : 14}
    var bottomPadding: CGFloat { isViewOnly ? Spacing.lg : 0}
    var topPadding: CGFloat { isViewOnly ? 20 : 16}
    
    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            EventTypeRow(type: type, message: message, isPending: true, openEventInfo: { openInfo()})
            eventDivider
            timeRow
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

private struct EventTypeRow: View {
    let type: Event.EventType
    let message: String?
    let isPending: Bool
        
    let openEventInfo: () -> ()
    
    var body: some View {
        HStack(spacing: iconGap) {
            Text(type.emoji)
                .font(.body(16, .bold))
                .frame(width: iconWidth)

            VStack(alignment: .leading, spacing: 6) {
                eventTypeAndInfoIcon
                
                if let message {
                    eventMessage(text: message)
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
            HStack(alignment: .top, spacing: 12) {
                Text(type.longTitle)
                    .font(.body(16, .bold))
                
                infoIcon
            }
        }
        .growButton()
    }
    
    private var infoIcon: some View {
        Image(systemName: "info.circle")
            .foregroundStyle(Color.textTertiary)
            .font(.body(11, .medium))
            .offset(x: isPending ? -8 : 0, y: isPending ? -2 : 0) //Closer if it is
    }
    
    private func eventMessage(text: String) -> some View {
        Text(text)
            .font(.body(14, .regularItalic))
            .foregroundStyle(Color.textSecondary.opacity(0.7)) //Tad lighter than normal secondary
            .lineLimitAndShrink(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

//When it is just showing the time
private struct EventTimeRow: View {
    
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

//A selectable version of EventTimeRow
private struct RespondEventTimeRow: View {
    @Binding var proposedTimes: ProposedTimes
    
    var body: some View {
        
    
    }
}


private struct EventPlaceRow: View {
    let location: EventLocation
        
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
