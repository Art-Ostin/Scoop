//
//  EventDetailsContainer.swift
//  Scoop
//
//  Created by Art Ostin on 17/04/2026.
//

import SwiftUI

struct EventDetailsContainer: View {
    @Bindable var ui: EventUIState
    let event: UserEvent
    var hasMessage: Bool { event.message?.isEmpty == false }
    
    @State var selectedTab: Int = 1
    @State var frameHeight: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                EventDetailsView(ui: ui, event: event)
                    .tag(1)
                
                EventDetailsInfo()
                    .tag(2)
            }
            .frame(height: max(frameHeight, 1))
            .onPreferenceChange(EventDetailsHeight.self) { measuredFrameHeight in
                print("THe parent Measured Height IS: \(measuredFrameHeight)")
                frameHeight = measuredFrameHeight
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .padding(.top, hasMessage ? 26 : 22)
        .padding(.bottom, hasMessage ? 16 : 22)
        .padding(.horizontal, 24)
        .background (
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .stroke(24, lineWidth: 1, color: Color(red: 0.93, green: 0.93, blue: 0.93)) //Color(red: 0.93, green: 0.93, blue: 0.93)
        .overlay(alignment: .topLeading) {
            eventDetailsOverlay
        }
        .overlay(alignment: .bottomTrailing) {
            infoOverlay
                .padding()
                .padding(.vertical, -2)
        }
    }
}

extension EventDetailsContainer {
    
    private var eventDetailsOverlay: some View {
        Text("Details")
            .font(.custom("SFProRounded-Medium", size: 10))
            .foregroundStyle(Color(red: 0.68, green: 0.68, blue: 0.68))
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(stops: [
                            .init(color: Color(red: 0.99, green: 0.98, blue: 0.97), location: 0.0),
                            .init(color: Color(red: 0.99, green: 0.98, blue: 0.97), location: 0.5),
                            .init(color: .white,  location: 0.5),
                            .init(color: .white,  location: 1.0)
                        ], startPoint: .top, endPoint: .bottom)
                    )
            )
            .padding(.horizontal, 24)
            .offset(y: -5)
    }
    
    private var infoOverlay: some View {
        Image(systemName: "info.circle")
            .font(.body(13, .medium))
            .foregroundStyle(Color(red: 0.66, green: 0.66, blue: 0.66))
    }
}

