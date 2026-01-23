//
//  EventDetailFormatter.swift
//  Scoop
//
//  Created by Art Ostin on 21/01/2026.
//

import SwiftUI

struct EventTextFormatter: View {
    
    @Bindable var ui: EventUIState
    let profile: ProfileModel
    let event: UserEvent

    private var formattedTime: String {
        event.time.formatted(.dateTime.hour().minute())
    }
    
    private var place: String {
        let place = event.place.name ?? (event.type != .drink ? "the venue" : "the bar")
        if place.count > 15 {
            return (event.type != .drink ? "the venue" : "the bar")
        } else {
            return place
        }
    }
    
    private var weekdayDate: String {
        let date = event.time
        return date.formatted(.dateTime.weekday(.wide))
    }
    
    private var otherPerson: String {
        event.otherUserName
    }
    
    private var title: String {
        switch event.type {
        case .drink:
            "Drink with \(otherPerson)"
        case .doubleDate:
            "Double Date with \(otherPerson)"
        case .socialMeet:
            "Social with \(otherPerson)"
        case .custom:
            "Custom Date with \(otherPerson)"
        }
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.body(20, .bold))

                Text(EventFormatting.dayAndTime(event.time))
                    .foregroundStyle(Color(red: 0.32, green: 0.32, blue: 0.32))
                    .font(.body(16, .regular))
                
                address
            }
            
            confirmedText
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            eventDetailsButton
        }
    }
}

extension EventTextFormatter {
    
    private var whatToDoText: Text {
        Text("Hello")
//        switch event.type {
//        case .socialMeet:
//            Text("On \(formattedDate) go to \(place) for \(formattedTime) with your mates & \(otherPerson) and their friends will also be there")
//        case .doubleDate:
//            Text("On \(formattedDate) go to \(place) for \(formattedTime) with your friend & meet \(otherPerson) & their friend there for the double date")
//        case .drink:
//            Text("On \(formattedDate) go to \(place) for \(formattedTime), meet \(otherPerson) & have a drink together")
//        case .custom:
//            Text("On \(formattedDate) go to \(place) for \(formattedTime), meet \(otherPerson) & do whatever you've planned!")
//        }
    } //On \(weekdayDate)
    
    private var address: some View {
        Button {
            Task { await MapsRouting.openMaps(place: event.place) }
        } label: {
            Text(EventFormatting.placeFullAddress(place: event.place))
                .font(.body(12, .regular))
                .underline(color: .grayText)
                .foregroundStyle(Color.grayText)
                .frame(width: 300, alignment: .leading)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var confirmedText: Text {
        Text("You’ve both confirmed so don’t worry, they’ll be there! If you stand them up you're ")
            .foregroundStyle(Color.grayText)
            .font(.body(16, .medium))

        + Text("blocked.")
            .font(.body(16, .bold))
            .underline()
            .foregroundStyle(Color.black)
    }

    private var eventDetails: Text {
        let typedMessage = event.message ?? ""
        
        return Text(title)
            .font(.body(16, .medium))
        + Text(typedMessage.isEmpty ? "" : ": \(typedMessage)")
            .font(.body(15, .regular))
    }
    
    private var actionBar: some View {
        HStack {
            Button {
                ui.showCantMakeIt = profile
            } label: {
                Text("Can't Make it?")
                    .font(.body(16))
                    .foregroundStyle(.accent)
                    .padding(24)
                    .contentShape(Rectangle())
                    .padding(-24)
            }
            Spacer ()
            
            Button {
                print("Hello world")
            } label: {
                Text("")
            }
        }
    }
    
    private var eventDetailsButton: some View {
        Button {
            ui.showEventDetails = event
        } label: {
            HStack(spacing: 10) {
                Image("CoolGuys")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                Text("Drink")
                    .font(.body(17, .bold))
            }
            .padding(6)
            .padding(.horizontal, 4)
            .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.background)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 2)
                )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
