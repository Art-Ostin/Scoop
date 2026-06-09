//
//  EventInfo.swift
//  Scoop Test
//
//  Created by Art Ostin on 09/06/2026.
//

import SwiftUI

struct EventInfo: View {
    
    let location: EventLocation
    let eventTime: Date
    let otherUserName: String
    let evenType: Event.EventType
    
    
    @State var scrollProgress: Double = 0
    
    
    
    var body: some View {
        VStack(spacing: 36){
            Text("How it Works")
                .font(.system(size: 24, weight: .medium, design: .serif))
            
            VStack(spacing: 12) {
                scrollSection
                AnimatedPageIndicator(count: EventInfoData.allCases.count, progress: scrollProgress)
            }
        }
    }
}

extension EventInfo {
    
    var scrollSection: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(EventInfoData.allCases, id: \.self) { infoType in
                    eventInfoSlot(type: infoType)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging) // Makes scroll view snap to each place.
        .onScrollGeometryChange(for: Double.self) { geo in
            let width = geo.containerSize.width
            return width > 0 ? geo.contentOffset.x / width : 0
        } action: { _, newValue in
            scrollProgress = newValue
        } //Updates the scrollView
    }
    
    private func eventInfoSlot(type: EventInfoData) -> some View {
        VStack(spacing: 24) {
            Image(type.image)
                .resizable()
                .scaledToFill()
                .frame(width: 250, height: 250)
            Text(type.text(location: location, eventTime: eventTime, otherUserName: otherUserName, eventType: evenType))
                .font(.body(15, .medium))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .containerRelativeFrame(.horizontal)
    }
}


enum EventInfoData: CaseIterable {
    case confirmed, eventType, message, noShow
    
    //Update when I actually have an image to add
    var image: String {
        switch self {
        case .confirmed:
            return "CoolGuys"
        case .eventType:
            return "CoolGuys"
        case .message:
            return "CoolGuys"
        case .noShow:
            return "CoolGuys"
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
