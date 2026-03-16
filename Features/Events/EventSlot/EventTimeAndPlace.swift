//
//  EventTimeAndPlace.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct EventTimeAndPlace: View {
    
    @Bindable var ui: EventUIState
    
    let event: UserEvent
    let openInMaps: () -> ()
    
    var body: some View {
        VStack(spacing: 24) {
            
            if let time = event.acceptedTime {
                timeAndPlaceView(time)
                clockView(time)
            }
        }
    }
    
    private func timeAndPlaceView(_ time: Date) -> some View {
        VStack(spacing: 14) {
            Text(EventFormatting.dayAndTime(time))
            Button {
                openInMaps()
            } label :  {
                Text(EventFormatting.placeName(event.location))
                    .foregroundStyle(.accent)
            }
        }
        .font(.body(24, .bold))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func clockView(_ time: Date) -> some View {
        LargeClockView(targetTime: time) {}
            .onTapGesture {ui.showEventDetails = event}
    }
}
