//
//  EventSlotContainer.swift
//  Scoop
//
//  Created by Art Ostin on 01/05/2026.
//

import SwiftUI

struct EventSlotContainer: View {
    
    @State private var disableMap: Bool = true
    @State private var listenToScroll: Bool = false
    
    @Bindable var ui: EventUIState
    let eventProfile: EventProfile
    let imageSize: CGFloat
    
    let openMaps: () -> ()
    
    var body: some View {
        ScrollViewReader { proxy  in
            CustomTabPage(page: .meetingEvent, tabAction: .constant(false)) {
                VStack(spacing: 32) {
                    EventImageView(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
                    clockView
                    eventDetailsContainer
                    eventMap(proxy: proxy)
                        .id("MapsView")
                    howItWorksView
                    cantMakeItButton
                }
                .padding(.bottom, 72)
            }
            .onChange(of: disableMap) { oldValue, newValue in
                //If map switched to become not disabled trigger
                if oldValue && !newValue   {
                    Task {
                        try? await Task.sleep(for: .seconds(1))
                        listenToScroll = true
                    }
                } else if newValue {
                    listenToScroll = false
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { oldY, newY in
                guard listenToScroll else { return }
                if abs(newY - oldY) > 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        disableMap = true
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {messageButton}
        }
    }
}

// Different Views
extension EventSlotContainer {
    
    @ViewBuilder
    private var clockView: some View {
        if let acceptedTime = eventProfile.event.acceptedTime {
            LargeClockView(targetTime: acceptedTime, showShadow: false)
        }
    }
    
    private var eventDetailsContainer: some View {
        EventDetailsContainer(ui: ui, event: eventProfile.event){ openMaps()}
            .opacity(disableMap ? 1 : 0.5)
            .onTapGesture {
                if !disableMap {
                    disableMap.toggle()
                }
            }
    }
    
    private func eventMap(proxy: ScrollViewProxy) -> some View {
        EventMapView(
            proxy: proxy,
            event: eventProfile.event,
            imageSize: imageSize,
            disableMap: $disableMap
        ) {
            openMaps()
        }
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
                .font(.body(14, .bold))
                .contentShape(Rectangle())
                .foregroundStyle(Color.accent)
                .padding(.trailing, 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var messageButton: some View {
        Button {
            ui.messageProfile = eventProfile
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
