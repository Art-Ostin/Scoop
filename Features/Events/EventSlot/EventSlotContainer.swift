//
//  EventSlot.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/08/2025.
//

import SwiftUI
import MapKit
import Contacts


struct EventSlotContainer: View {
    
    let vm: EventViewModel
    let isFrozenEvent: Bool
    
    @Binding var showfrozenInfo: Bool
    
    @State var eventProfile: EventProfile
    @Bindable var ui: EventUIState
    @State private var imageSize: CGFloat = 0

    var body: some View {
        CustomTabPage(page: .meetingEvent, tabAction: $ui.showMessageScreen) {
            EventImageView(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
            EventHeaderDetails(ui: ui, event: eventProfile.event) {openMaps()}
            EventMapView(event: eventProfile.event, imageSize: imageSize) {openMaps()}
            EventInfoView(ui: ui, event: eventProfile.event) {openMaps()}
                .padding(.bottom, 144)
        }
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) { screenWidth in
            imageSize = screenWidth - 32 //Adds 24 padding on each side
        }
        .scrollIndicators(.hidden)
        .customScrollFade(height: 100, showFade: true)
    }
}

extension EventSlotContainer {
    
    @discardableResult
    private func openMaps() -> Bool {
        MapsRouter.openMaps(defaults: vm.defaults, item: eventProfile.event.location.mapItem, withDirections: true)
    }
}
