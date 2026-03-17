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
    
    @Environment(\.appState) private var state
    
    let vm: EventViewModel
    
    @State var eventProfile: EventProfile
    @Bindable var ui: EventUIState
    @State private var imageSize: CGFloat = 0
    
    private var isFrozenEvent: Bool {
        state.wrappedValue == .frozen
    }
    
    var body: some View {
        EventImageView(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
        EventHeaderDetails(ui: ui, event: eventProfile.event) {openMaps()}
        EventMapView(event: eventProfile.event, imageSize: imageSize) {openMaps()}
        EventInfoView(ui: ui, event: eventProfile.event) {openMaps()}
            .padding(.bottom, 96)
    }
}

extension EventSlotContainer {
    
    @discardableResult
    private func openMaps() -> Bool {
        MapsRouter.openMaps(defaults: vm.defaults, item: eventProfile.event.location.mapItem, withDirections: true)
    }
}
