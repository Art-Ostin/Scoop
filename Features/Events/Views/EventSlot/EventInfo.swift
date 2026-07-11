//
//  EventInfo.swift
//  Scoop
//
//  Created by Art Ostin on 09/06/2026.
//

import SwiftUI

struct EventInfo: View {
    
    //Injected
    let location: EventLocation
    let eventTime: Date
    let otherUserName: String
    let eventType: Event.EventType

    //Local view state
    @State private var scrollProgress: Double = 0


    var body: some View {
        VStack(spacing: Spacing.xl){
            Text("\(eventType.emoji) \(eventType.longTitle)")
                .font(.system(size: 24, weight: .medium, design: .serif))
            scrollSection
            AnimatedPageIndicator(count: EventInfoData.allCases.count, progress: scrollProgress)
        }
    }
}

extension EventInfo {
    
    var scrollSection: some View {
        PagerScrollView(progress: $scrollProgress) {
            ForEach(EventInfoData.allCases, id: \.self) { infoType in
                eventInfoSlot(type: infoType)
            }
        }
        .padding(.horizontal, -Spacing.gutter) // Negates the card gutter so the carousel is full-bleed
    }
    
    private func eventInfoSlot(type: EventInfoData) -> some View {
        VStack(spacing: Spacing.xl) {
            Image(type.image)
                .resizable()
                .scaledToFill()
                .frame(width: 250, height: 250)
            Text(type.text(location: location, eventTime: eventTime, otherUserName: otherUserName, eventType: eventType))
                .font(.body(17, .medium))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.margin)
        }
        .containerRelativeFrame(.horizontal)
    }
}


enum EventInfoData: CaseIterable {
    case confirmed, eventType, message, noShow
    
    //Update when I actually have an image to add
    var image: String {
        switch self {
        case .confirmed: "CoolGuys"
        case .eventType: "CoolGuys"
        case .message: "CoolGuys"
        case .noShow: "CoolGuys"
        }
    }
    
    //The text for each part
    func text(location: EventLocation, eventTime: Date, otherUserName: String, eventType: Event.EventType) -> String {
        switch self {
        case .confirmed:
            let location = location.name ?? "the venue"
            let time = FormatEvent.messageTime(eventTime, withToday: false)
            return "You've both confirmed you're going to meet at \(location) on \(time)"
        case .eventType:
            return eventType.howItWorksEvent(otherUserName) // Need to update
        case .message:
            return "Text to coordinate details and find one another when its time"
        case .noShow:
            return "You’ve both confirmed so they’ll be there! If you don’t show you’re blocked!"
        }
    }
}
