//
//  EventSlotContainer.swift
//  Scoop
//
//  Created by Art Ostin on 01/05/2026.
//

import SwiftUI

struct EventSlotContainer: View {
    
    @State private var disableMap: Bool = true
    @State private var mapEnabledAt: Date?
    
    @Bindable var ui: EventUIState
    let eventProfile: EventProfile
    let imageSize: CGFloat
    let zoomNS: Namespace.ID
    
    let openMaps: () -> ()
    
    var body: some View {
        VStack(spacing: 32) {
            EventImageView(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
            clockView
            eventDetailsContainer
            EventMap(location: eventProfile.event.location, imageSize: imageSize, disableMap: $disableMap, openMaps: openMaps)
            eventDivider
            eventInfoSection
        }
        .padding(.bottom, 72)
    }
}

// Different Views
extension EventSlotContainer {
    
    private var clockView: some View {
        eventProfile.event.acceptedTime.map {
            EventClock(targetTime: $0)
        }
    }
    
    @ViewBuilder
    private var eventInfoSection: some View {
        let e = eventProfile.event
        if let acceptedTime = e.acceptedTime {
            EventInfo(location: e.location, eventTime: acceptedTime, otherUserName: e.otherUserName, evenType: e.type)
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
                place: event.location
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

//Views Buttons
extension EventSlotContainer {
    
    
    private var messageButton: some View {
        NavigationLink(value: eventProfile) {
            Image("NewMessageIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .font(.body(17, .bold))
                .padding(10)
//                            .hoverButton()
                .opacity(disableMap ? 1 : 0.5)
                .expandHitArea(24)
//                            .padding(.bottom, 96)
//                            .padding(.horizontal, 24)
        }
        .matchedTransitionSource(id: eventProfile.id, in: zoomNS)
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
                    .shadow(color: .black.opacity(0.025), radius: 4, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.015), radius: 12, x: 0, y: 0)
            )
    }
    
    //Put eventTextOverlay as viewExtension as used also in details view
    func eventTextOverlay() -> some View {
        self
            .font(.custom("SFProRounded-Semibold", size: 13))
            .foregroundStyle(Color(white: 0.68))
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

 */
