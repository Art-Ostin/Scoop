//
//  EventDetailFormatter.swift
//  Scoop
//
//  Created by Art Ostin on 21/01/2026.
//

import SwiftUI


struct EventTextFormatter: View {
    
    @Binding var showCantMakeItView: Bool
    
    
    let event: UserEvent
    
    private var formattedTime: String {
        let eventTime = event.time
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "HH:mm"
        return f.string(from: eventTime)
    }
    
    private var place: String {
        event.place.name ?? (event.type != .drink ? "the venue" : "the bar")
    }
    
    private var otherPerson: String {
        event.otherUserName
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 24) {
            Text("What to Do")
                .font(.body(20, .bold))
            
            whatToDoText
                .font(.body(16, .medium))
            
            (
                Text("You’ve both confirmed so don’t worry, they’ll be there! If you stand them up you’re ")
                    .font(.body(16, .medium))
                +
                Text("blocked")
                    .font(.body(16, .bold))
                    .underline()
            )
        
            Button {
                showCantMakeItView = true
            } label: {
                Text("Can't make it")
                    .font(.body(16))
                    .foregroundStyle(.accent)
                    .padding(24)
                    .contentShape(Rectangle())
                    .padding(-24)
            }
        }
    }
}

extension EventTextFormatter {
    private var whatToDoText: some View {
        switch event.type {
        case .socialMeet:
            Text ("Go to \(place) for \(formattedTime) with your mates & \(otherPerson) and their friends will also be there")
        case .doubleDate:
            Text ("Go to \(place) for \(formattedTime) with your friend & \(otherPerson) and their friend there for the double date")
        case .drink:
            Text("Go to \(place) for \(formattedTime), meet \(otherPerson) & have a drink together")
        case .custom:
            Text("Go to \(place) for \(formattedTime), meet \(otherPerson) & do whatever you have planned together!")
        }
    }
    

    
    
}





//#Preview {
//    EventTextFormatter(time: Date(timeIntervalSince1970: 1_704_158_600))
//}
