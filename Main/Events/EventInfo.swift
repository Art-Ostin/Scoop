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
            "Drink with \(otherPerson)"
        }
    }
    
    private var formattedDate: String {
        let date = event.time

        let weekday = date.formatted(.dateTime.weekday(.wide))
        let month = date.formatted(.dateTime.month(.abbreviated))

        let day = Calendar.current.component(.day, from: date)
        return "\(weekday) \(day)\(ordinalSuffix(for: day)) \(month)"
    }

    private func ordinalSuffix(for day: Int) -> String {
        let mod100 = day % 100
        if (11...13).contains(mod100) { return "th" }

        switch day % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 24) {
            VStack {
                
                HStack {
                    Text(title)
                        .font(.body(20, .bold))
                    
                    Spacer()
                    
                }
            }
            
            whatToDoText
                .foregroundStyle(Color.grayText)
                .font(.body(16, .medium))
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            confirmedText
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            actionBar
            
            eventDetailsButton
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(y: -12)
        }
    }
}

extension EventTextFormatter {
    
    private var whatToDoText: Text {
        switch event.type {
        case .socialMeet:
            Text("On \(formattedDate) go to \(place) for \(formattedTime) with your mates & \(otherPerson) and their friends will also be there")
        case .doubleDate:
            Text("On \(formattedDate) go to \(place) for \(formattedTime) with your friend & meet \(otherPerson) & their friend there for the double date")
        case .drink:
            Text("On \(formattedDate) go to \(place) for \(formattedTime), meet \(otherPerson) & have a drink together")
        case .custom:
            Text("On \(formattedDate) go to \(place) for \(formattedTime), meet \(otherPerson) & do whatever you've planned!")
        }
    } //On \(weekdayDate)
    
    private var address: some View {
        Button {
            Task { await MapsRouting.openMaps(place: event.place) }
        } label: {
            Text(EventFormatting.placeFullAddress(place: event.place))
                .font(.body(12, .regular))
                .underline(color: .grayText)
                .foregroundStyle(Color.grayText)
                .frame(width: 240, alignment: .leading)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var confirmedText: Text {
        Text("You’ve both confirmed so don’t worry, they’ll be there! If you stand them up you’re ")
            .foregroundStyle(Color.grayText)
            .font(.body(16, .medium))

        + Text("blocked")
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
