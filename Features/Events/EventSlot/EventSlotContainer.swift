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
        ZStack {
            ScrollView {
                VStack(spacing: 36) {
                    titleView
                    EventImageView(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
                    EventHeaderDetails(ui: ui, event: eventProfile.event) {openMaps()}
                    EventMapView(event: eventProfile.event, imageSize: imageSize) {openMaps()}
                    EventInfoView(ui: ui, event: eventProfile.event) {openMaps()}
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 144)
            .overlay(alignment: .topTrailing) {messageButton}
        }
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) { screenWidth in
            imageSize = screenWidth - 48 //Adds 24 padding on each side
        }
        .scrollIndicators(.hidden)
        .customScrollFade(height: 100, showFade: true)
    }
}

extension EventSlotContainer {
    
    private var titleView: some View {
        
        HStack(alignment: .top, spacing: 6) {
            Text("Meeting")
                .font(.custom("SFProRounded-Bold", size: 32))
            
            if isFrozenEvent {
                Button {
                    showfrozenInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color(red: 0.26, green: 0.26, blue: 0.26))
                        .contentShape(Circle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
        
    private var messageButton: some View {
        Button {
            ui.showMessageScreen = eventProfile.profile
        } label: {
            Image("roundMessageIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .font(.body(17, .bold))
                .padding(6)
                .glassIfAvailable(isClear: true)
                .padding(24) //Expands Tap Area
                .contentShape(Rectangle())
                .padding(-24)
                .padding(.horizontal, 24)
                .padding(.vertical, 6)
        }
    }
    
    @discardableResult
    private func openMaps() -> Bool {
        MapsRouter.openMaps(defaults: vm.defaults, item: eventProfile.event.location.mapItem, withDirections: true)
    }
}


