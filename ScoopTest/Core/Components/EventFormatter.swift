//
//  EventFormatter.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/08/2025.
//

import SwiftUI

struct EventFormatter: View {
    
    let event: UserEvent
    let isInvite: Bool
    let size: CGFloat
    
    init (event: UserEvent, isInvite: Bool = true, size: CGFloat = 22) {
        self.event = event
        self.isInvite = isInvite
        self.size = size
    }
    
    var body: some View {
        
        var isMessage: Bool { event.message?.isEmpty == false }
        let time = formatTime(date: event.time)
        let type = event.type ?? ""
        let place = event.place?.name  ?? ""
        let header =  Text("\(time), \(type), ") + Text(place).foregroundStyle(isInvite ? Color.appGreen : Color.accent).font(.body(size, .bold))
        
        return VStack(alignment: isMessage ? .leading: .center, spacing: isMessage ? 16 : 0) {
            
            header
                .font(.body(size))
                .multilineTextAlignment(isMessage ? .leading : .center)
                .lineSpacing(isMessage ? 4 : 12)
            
            
            if let message = event.message {
                Text (message)
                    .font(.body(.italic))
                    .foregroundStyle(Color.grayText)
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
}
