//
//  EventSlotContainer.swift
//  Scoop
//
//  Created by Art Ostin on 01/05/2026.
//

import SwiftUI

struct EventSlot: View {
    
    //Injected
    @Bindable var ui: EventsUIState
    let eventProfile: EventProfile
    let imageSize: CGFloat
    let userImage: UIImage
    let openMaps: () -> ()

    //Local view state
    @State private var disableMap: Bool = true
    @State private var mapEnabledAt: Date?

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
                profileImages: ui.profileImages[eventProfile.profile.id] ?? [],
                userImage: userImage,
                targetTime: targetTime,
                openProfile: { ui.selectedProfile = eventProfile.profile }
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
    

    private func disableMapOnScroll(_ oldY: CGFloat, _ newY: CGFloat) {
        guard let enabledAt = mapEnabledAt, Date.now.timeIntervalSince(enabledAt) > 1,
              abs(newY - oldY) > 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            disableMap = true
        }
    }
    
    private var eventDivider: some View {
        Capsule()
            .fill(Color.border)
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
    func eventCardBackground() -> some View {
        self
            .frame(maxWidth: .infinity)
            .background (Color.appCanvas, in: .rect(cornerRadius: CornerRadius.md))
            .padding(.horizontal, 16)
            .compositingGroup()
            .shadow(.card)
            .stroke(CornerRadius.md, lineWidth: 0.85)
    }
    
    //Put eventTextOverlay as viewExtension as used also in details view
    func eventTextOverlay(isDetails: Bool = false) -> some View {
        self
            .font(.title(13, .semibold))
            .foregroundStyle(isDetails ? Color.textAccent : Color.textTertiary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.appCanvas)
            .padding(.horizontal, 36)//Indent in by 16
            .offset(y: -10)//Shifts it up
    }
}
