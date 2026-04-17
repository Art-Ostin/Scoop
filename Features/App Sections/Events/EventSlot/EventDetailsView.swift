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
        VStack(alignment: .leading, spacing: 28) {
            detailRow
            timeRow
            placeRow
        }
        .padding(.top, 26)
        .padding(.bottom, 22)
        .padding(.horizontal, 24)
        .background (
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .stroke(24, lineWidth: 1, color: Color(red: 0.93, green: 0.93, blue: 0.93))
        .overlay(alignment: .topLeading) {
            eventDetailsOverlay
        }
        .overlay(alignment: .topTrailing) {
            infoOverlay
                .padding()
        }
    }
    
    private var detailRow: some View {
        HStack(spacing: 16) {
            Text(event.type.description.emoji)
                .offset(x: -3)
            (
                Text("\(event.type.description.label): ")
                +
                Text(event.message ?? "")
                   .font(.footnote)
                   .foregroundStyle(Color.gray)
            )
            Spacer()
        }
        .font(.body(18, .medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, -20)
    }
    
    private var timeRow: some View{
        HStack(spacing: 24) {
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
