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
            eventMap()
            howItWorksView
            cantMakeItButton
        }
        .padding(.bottom, 72)
    }
}

// Different Views
extension EventSlotContainer {
    
    private var clockView: some View {
        eventProfile.event.acceptedTime.map {
            LargeClockView(targetTime: $0, showShadow: false)
        }
    }
    
    private var eventDetailsContainer: some View {
        EventDetailsContainer(ui: ui, event: eventProfile.event){ openMaps()}
            .dimWhenMapActive($disableMap)
    }
    
    private func eventMap() -> some View {
        EventMapView(
            event: eventProfile.event,
            imageSize: imageSize,
            disableMap: $disableMap
        ) {
            openMaps()
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
}

//Views Buttons
extension EventSlotContainer {
    
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
    
    private var messageButton: some View {
        NavigationLink(value: eventProfile) {
            Image("NewMessageIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .font(.body(17, .bold))
                .padding(10)
            //                .hoverButton()
                .opacity(disableMap ? 1 : 0.5)
                .expandHitArea(24)
            //                .padding(.bottom, 96)
            //                .padding(.horizontal, 24)
        }
        .matchedTransitionSource(id: eventProfile.id, in: zoomNS)
    }
}

private extension View {
    func dimWhenMapActive(_ disableMap: Binding<Bool>) -> some View {
        opacity(disableMap.wrappedValue ? 1 : 0.5)
            .onTapGesture {
                if !disableMap.wrappedValue { disableMap.wrappedValue = true }
            }
    }
}

