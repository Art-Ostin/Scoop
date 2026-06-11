//
//  EventSlotContainer.swift
//  Scoop
//
//  Created by Art Ostin on 01/05/2026.
//

import SwiftUI

struct EventSlot: View {
    
    @State private var disableMap: Bool = true
    @State private var mapEnabledAt: Date?
    
    @Bindable var ui: EventUIState
    let eventProfile: EventProfile
    let imageSize: CGFloat
    let userImage: UIImage

    let openMaps: () -> ()
    
    var body: some View {
        VStack(spacing: 36) {
            eventImageCard
            eventDetailsContainer
                .padding(.top, 4)//Looks more natural as detailTitle pokes up a top.
            eventDivider
            eventInfoSection
            eventDivider
            EventMap(location: eventProfile.event.location, imageSize: imageSize, disableMap: $disableMap, openMaps: openMaps)
        }
        .padding(.bottom, 72)
    }
}

// Different Views
extension EventSlot {
    
    @ViewBuilder
    private var eventImageCard: some View {
        eventProfile.event.acceptedTime.map { targetTime in
            EventImageCard(
                ui: ui,
                eventProfile: eventProfile,
                imageSize: imageSize,
                userImage: userImage,
                targetTime: targetTime
            )
        }
    }
    
    
    @ViewBuilder
    private var eventInfoSection: some View {
        let e = eventProfile.event
        if let acceptedTime = e.acceptedTime {
            EventInfo(location: e.location, eventTime: acceptedTime, otherUserName: e.otherUserName, eventType: e.type)
        }
    }
    
    @ViewBuilder
    private var eventDetailsContainer: some View {
        let event = eventProfile.event
        if let acceptedTime = event.acceptedTime {
            EventDetails(
                type: event.type,
                message: event.message,
                time: acceptedTime,
                place: event.location,
                openMaps: openMaps
            )
                .dimWhenMapActive($disableMap)
        }
    }
    
    
    private var howItWorksView: some View {
        CoreInfoPage(event: eventProfile.event)
            .dimWhenMapActive($disableMap)
    }
    
    private func disableMapOnScroll(_ oldY: CGFloat, _ newY: CGFloat) {
        guard let enabledAt = mapEnabledAt, Date.now.timeIntervalSince(enabledAt) > 1,
              abs(newY - oldY) > 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            disableMap = true
        }
    }
    
    private var eventDivider: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color(white: 0.8))
            .frame(maxWidth: .infinity, maxHeight: 1)
            .padding(.horizontal, 72)
            .padding(.vertical, 4)//add tad more padding here than default
    }
}

extension View {
    
    func dimWhenMapActive(_ disableMap: Binding<Bool>) -> some View {
        opacity(disableMap.wrappedValue ? 1 : 0.5)
            .onTapGesture {
                if !disableMap.wrappedValue { disableMap.wrappedValue = true }
            }
    }
    
    //Used on all the cards
    func eventCardShadowBackground() -> some View {
        self
            .background (
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCanvas)
                    .shadow(color: Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.0125), radius: 4, x: 0, y: 1)
                    .shadow(color: Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.0075), radius: 12, x: 0, y: 0)
            )
            .stroke(16, lineWidth: 1, color: Color(white: 0.93))
    }
    
    //Put eventTextOverlay as viewExtension as used also in details view
    func eventTextOverlay(isDetails: Bool = false) -> some View {
        self
            .font(.custom("SFProRounded-Semibold", size: 13))
            .foregroundStyle(isDetails ? Color(red: 0.55, green: 0, blue: 0.25) : Color(white: 0.68))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.appCanvas)
            .padding(.horizontal, 36)//Indent in by 16
            .offset(y: -10)//Shifts it up
    }
}



/*
 cantMakeItButton

 private var cantMakeItButton: some View {
     Button {
         ui.showCantMakeIt = eventProfile
     } label: {
         Text("Can't Make It?")
             .font(.body(14, .bold))
             .contentShape(Rectangle())
             .foregroundStyle(Color.accent)
             .padding(.trailing, 24)
     }
     .frame(maxWidth: .infinity, alignment: .leading)
 }
 
 
 private var clockView: some View {
     eventProfile.event.acceptedTime.map {
         EventClock(targetTime: $0)
     }
 }


 */
