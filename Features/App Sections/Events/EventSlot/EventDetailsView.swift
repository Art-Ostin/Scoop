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
    
    var hasMessage: Bool { event.message?.isEmpty == false }
    
    var body: some View {
        VStack(alignment: .leading, spacing: hasMessage ? 24 : 28) {
            detailRow
            timeRow
            placeRow
            messageRow
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
        .overlay(alignment: .topTrailing) {
            infoOverlay
                .padding()
                .padding(.vertical, -2)
        }
    }
    
    private var detailRow: some View {
        HStack(spacing: 16) {
            Text(event.type.description.emoji)
                .offset(x: -3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(event.type.longTitle)")
//                Text(event.message ?? "")
//                   .font(.footnote)
//                   .foregroundStyle(Color.gray)
            }
        }
        .font(.body(18, .medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, -20)
    }
    
    private var timeRow: some View{
        HStack(spacing: 18) {
            Image("Clock")
                .resizable()
                .frame(width: 20, height: 20)
                .offset(x: -4)
            if let acceptedTime =  event.acceptedTime {
                Text(FormatEvent.dayAndTime(acceptedTime, withHour:  true))
                    .font(.body(18, .medium))
            }
        }
    }
    
    @ViewBuilder
    private var messageRow: some View {
        if let message = event.message {
            HStack(spacing: 18) {
                Text("💬")
                    .offset(x: -2)
                
                Text(message)
                    .font(.body(14))
                    .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
                    .lineSpacing(6)
                    .kerning(0.2)
            }
            .padding(.top, -4)
        }
    }
    
    private var placeRow: some View {
        InviteCardPlaceRow(location: event.location, isMeetUp: true)
    }
    
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
