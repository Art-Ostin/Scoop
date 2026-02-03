//
//  EventFormatter.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/08/2025.
//

import SwiftUI

struct EventFormatter: View {

    let time: Date
    let type: EventType
    let message: String?
    let place: EventLocation
    let isInvite: Bool
    let size: CGFloat
    
    init(time: Date, type: EventType, message: String?, isInvite: Bool = true, place: EventLocation, size: CGFloat = 22) {
        self.time = time
        self.type = type
        self.message = message
        self.place = place
        self.isInvite = isInvite
        self.size = size
    }
    
    var body: some View {
        let hasMessage = (message?.isEmpty == false)
        let time = formatTime(date: time)
        let place = place.name ?? ""
        let header =  Text("\(time), \(type.description.label), ") + Text(place).foregroundStyle(isInvite ? Color.appGreen : Color.accent).font(.body(size, .bold))
        
        return VStack(alignment: (hasMessage || !isInvite) ? .leading : .center, spacing: hasMessage ? 16 : 0) {
            header
                .font(.body(size))
                .multilineTextAlignment((hasMessage || !isInvite) ? .leading : .center)
                .lineSpacing(hasMessage ? 4 : 12)
                .lineLimit(hasMessage ? 2 : 3)
            
            if let message {
                Text (message)
                    .font(.body(.italic))
                    .foregroundStyle(Color.grayText)
            }
        }
    }
}

func formatTime(date: Date?, withHour: Bool = true) -> String {
    guard let date = date else { return "" }
    let dayOfMonth = date.formatted(.dateTime.month(.abbreviated).day(.defaultDigits))
    let weekDay = date.formatted(.dateTime.weekday(.wide))
    let time = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
    
    if withHour {
        return "\(weekDay) (\(dayOfMonth)) \(time)"
    } else {
        return "\(weekDay) (\(dayOfMonth))"
    }
}
