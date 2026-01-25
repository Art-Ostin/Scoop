//
//  EventDetails.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct EventDetails: View {
    
    let vm: EventViewModel
    let event: UserEvent
    
    var body: some View {
        VStack(spacing: 36) {
            detailsTitle
            
            eventMeetingDescription(event: event)
            
            detailsImage
                .padding(.top, 24)
            
            Text("Good Luck!")
                .font(.body(20, .bold))
                .padding(.top, 24)
            
            cantMakeItButton
                .padding(.top, 24)
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 60)
    }
}

extension EventDetails {
    private var detailsTitle: some View {
        HStack(alignment: .bottom) {
            Text("How It Works")
                .font(.body(24, .bold))
            
            Spacer()
            
            Text("\(detailsTypeTitle)  ")
                .font(.body(20, .medium))
            + Text(event.type.description.emoji ?? "🦥")
                .font(.body(24, .medium))
        }
    }
    
    private var detailsTypeTitle: String {
        switch event.type {
        case .socialMeet:
            return "Social"
        case .doubleDate:
            return "Double Date"
        case .drink:
            return "Drink"
        case .custom:
            return "Custom Date"
        }
    }
    
    private var detailsText: some View {
        
        VStack(alignment: .leading, spacing: 24) {
            Text("You’ve both confirmed you’re meeting on Thursday 15th January at Barbossa for a drink")
            
            Text("So just meet Anne-sophie there at 22:30 & share a good evening together :) Text to find one another.")
            
            Text("Remember: A stranger is a lifetime of stories")
        }
        .font(.body(15, .italic))
        .foregroundStyle(Color.grayText)
        .lineSpacing(6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var detailsImage: some View {
        Image("CoolGuys")
            .resizable()
            .scaledToFit()
            .frame(width: 240, height: 240)
    }
    
    private func eventDetailsFormat(text1: String, text2: String, text3: String) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(text1)
            +
            Text(text2)
                .underline()
            Text(text3)
            Text("Remember: A stranger is a lifetime of stories")
        }
        .font(.body(15, .italic))
        .foregroundStyle(Color.grayText)
        .lineSpacing(6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func eventMeetingDescription(event: UserEvent) -> some View {
        let name = event.otherUserName
        var place = event.place.name ?? "the venue"
        if place.count > 20 { place = "the venue"}
        let fullTime = EventFormatting.fullDate(event.time)
        let opening = "You’ve both confirmed"
        
        let hour = event.time.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        
        var text1 = ""
        var text2 = ""
        var text3 = ""
        
        switch event.type {
        case .socialMeet:
            text1 = "\(opening) you're going to \(place) on \(fullTime)"
            text2 = "each with your friends"
            text3 = "So head there for \(hour) & meet \(name) & their friends there! Text to find one another :)"
            
           // You’ve both confirmed you’re going to Barbossa on Thursday 15th January, each with your own friends
        case .doubleDate:
            text1 = "\(opening) to meet on \(fullTime) at \(place) "
            text2 = "for a double date"
            text3 = "Go there with your friend at \(hour) & meet \(name) & their friend there! Text to find each other :)"
            
        case .drink:
            text1 = "\(opening) to meet on \(fullTime) "
            text2 = "for a drink"
            text3 = "So just meet \(name) there at \(hour) and share a good evening together! Text to find one another :)"
            
        case .custom:
            text1 = "\(opening) to meet on \(fullTime) at \(place)"
            text2 = ""
            text3 = "So just head there for \(hour) & do whatever you've planned! Text to find each other :)"
        }
        return eventDetailsFormat(text1: text1, text2: text2, text3: text3)
    }
    
    private var cantMakeItButton: some View {
        NavigationLink {
            CantMakeIt(vm: vm, event: event)
                .navigationBarTitleDisplayMode(.inline)
        } label: {
            HStack(spacing: 6){
                Text("Can't make it?")
            }
            .font(.body(15, .medium))
            .foregroundStyle(.accent)
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
    }
}
