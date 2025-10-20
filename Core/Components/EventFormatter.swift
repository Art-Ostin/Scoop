//
//  EventFormatter.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/08/2025.
//

import SwiftUI

struct EventFormatter: View {

    let time: Date
    let type: String
    let message: String?
    let place: EventLocation
    let isInvite: Bool
    let size: CGFloat
    let isProfile: Bool
    
    
    init(time: Date, type: String, message: String?, isInvite: Bool = true, place: EventLocation, size: CGFloat = 22, isProfile: Bool = false) {
        self.time = time
        self.type = type
        self.message = message
        self.place = place
        self.isInvite = isInvite
        self.size = size
        self.isProfile = isProfile
    }
    
    var body: some View {
        let hasMessage = (message?.isEmpty == false)
        let time = formatTime(date: time)
        let place = place.name ?? ""
        let header =  Text("\(time), \(type), ") + Text(place).foregroundStyle(isInvite ? Color.appGreen : Color.accent).font(.body(size, .bold))
        
        return VStack(alignment: (hasMessage || !isInvite) ? .leading : .center, spacing: hasMessage ? 16 : 0) {
            header
                .font(.body(size))
                .multilineTextAlignment((hasMessage || !isInvite) ? .leading : .center)
                .lineSpacing(hasMessage ? 4 : 12)
                .lineLimit(2)
            
            if let message {
                Text (message)
                    .font(.body(.italic))
                    .foregroundStyle(Color.grayText)
            }
        }
    }
}

func formatTime(date: Date?) -> String {
    guard let date = date else { return "" }
    let dayOfMonth = date.formatted(.dateTime.month(.abbreviated).day(.defaultDigits))
    let weekDay = date.formatted(.dateTime.weekday(.wide))
    let time = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
    
    return "\(weekDay) (\(dayOfMonth)) \(time)"
}
