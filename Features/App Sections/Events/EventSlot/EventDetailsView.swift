//
//  EventTimeAndPlace.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct EventDetailsView: View {
    
    @Bindable var ui: EventUIState
    
    let event: UserEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            detailRow
            timeRow
            placeRow
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background (
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .stroke(24, lineWidth: 1, color: Color(red: 0.93, green: 0.93, blue: 0.93))
        
    }
    
    
    private var detailRow: some View {
        HStack(spacing: 20) {
            Text(event.type.description.emoji)
            Text(event.type.description.label)
            Spacer()
        }
        .font(.body(18, .medium))
    }
    
    private var timeRow: some View{
        HStack(spacing: 8) {
            Image("MiniClockIcon")
                .scaleEffect(1.1)
            if let acceptedTime =  event.acceptedTime {
                Text(FormatEvent.dayAndTime(acceptedTime, withHour:  true))
                    .font(.body(18, .medium))
            }
        }
    }
    
    
    private var placeRow: some View {
        InviteCardPlaceRow(location: event.location, isMeetUp: true)
    }
    
    private var eventDetailsOverlay: some View {
        Text("Event Details")
            .font(.custom("SFProRounded-Medium", size: 10))
            .foregroundStyle(Color(red: 0.68, green: 0.68, blue: 0.68))
            .padding(.horizontal, 6)
            .background(Color.background)
    }
}




/*
 
 
 private func clockView(_ time: Date) -> some View {
     LargeClockView(targetTime: time) {}
         .onTapGesture {ui.showEventDetails = event}
 }

 
 if let time = event.acceptedTime {
     timeAndPlaceView(time)
     clockView(time)
 }
 */

/*
 private func timeAndPlaceView(_ time: Date) -> some View {
     VStack(spacing: 14) {
         Text(FormatEvent.dayAndTime(time))
         Button {
             openInMaps()
         } label :  {
             Text(FormatEvent.placeName(event.location))
                 .foregroundStyle(.accent)
         }
     }
     .font(.body(24, .bold))
     .multilineTextAlignment(.center)
     .frame(maxWidth: .infinity, alignment: .center)
 }

 */
