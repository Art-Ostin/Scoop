//
//  EventSlotContainer.swift
//  Scoop
//
//  Created by Art Ostin on 01/05/2026.
//

import SwiftUI

struct EventSlotContainer: View {
    
    @State private var disableMap: Bool = true
    
    @Bindable var ui: EventUIState
    let eventProfile: EventProfile
    let imageSize: CGFloat
    
    let openMaps: () -> ()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                EventImageView(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
                clockView
                eventDetailsContainer
                eventMap
                howItWorksView
                cantMakeItButton
            }
        }
        .scrollClipDisabled()
        .task { await loadProfileImages(eventProfile.profile)}
        .overlay(alignment: .bottomTrailing) {messageButton}
    }
}

// Different Views
extension EventSlotContainer {
    
    @ViewBuilder
    private var clockView: some View {
        if let acceptedTime = eventProfile.event.acceptedTime {
            LargeClockView(targetTime: acceptedTime, showShadow: false) {}
        }
    }
    
    private var eventDetailsContainer: some View {
        EventDetailsContainer(ui: ui, event: eventProfile.event)
            .opacity(disableMap ? 1 : 0.5)
            .onTapGesture {
                if !disableMap {
                    disableMap.toggle()
                }
            }
    }
    
    private var eventMap: some View {
        EventMapView(
            event: eventProfile.event,
            imageSize: imageSize,
            disableMap: $disableMap
        ) {
            openMaps(eventProfile)
        }
        .id("Map")
    }
    
    private var howItWorksView: some View {
        CoreInfoPage(event: eventProfile.event)
            .opacity(disableMap ? 1 : 0.5)
            .onTapGesture {
                if !disableMap {
                    disableMap.toggle()
                }
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
                .frame(maxWidth: .infinity, alignment: .trailing)
                .font(.body(14, .bold))
                .foregroundStyle(Color.accent)
                .padding(.trailing, 24)
        }
    }
    
    private var messageButton: some View {
        Button {
            tabProfile = eventProfile
        } label: {
            Image("NewMessageIcon") //NewMessageIcon
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .font(.body(17, .bold))
                .padding(10)
                .glassIfAvailable(isClear: true)
                .padding(24) //Expands Tap Area
                .contentShape(Rectangle())
                .padding(-24)
        }
        .padding(.bottom, 96)
        .padding(.horizontal, 24)
        .opacity(disableMap ? 1 : 0.5)
        .onTapGesture {
            if !disableMap {
                disableMap.toggle()
            }
        }
    }
}


/*
 .onScrollGeometryChange(for: CGFloat.self) { geometry in
     geometry.contentOffset.y
 } action: { oldValue, newValue in
     guard disableMap == false else {
         mapEnabledScrollOffset = nil
         return
     }
     
     if mapEnabledScrollOffset == nil {
         mapEnabledScrollOffset = oldValue
     }

     if let enabledOffset = mapEnabledScrollOffset,
        abs(newValue - enabledOffset) > 10 { //Virtually as soon start scrolling disable Maps View
         disableMap = true
         mapEnabledScrollOffset = nil
     }
 }

 .scrollPosition(id: $scrollTarget, anchor: .center)
 .customScrollFade(height: 100, showFade: true)

 */
