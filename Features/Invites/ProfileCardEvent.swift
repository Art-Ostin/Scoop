//
//  ProfileCardEvent.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI


struct ProfileCardEventInfo: View {
    
    let event: UserEvent
    var dates: [Date] {event.proposedTimes.dates.filter(\.stillAvailable).map(\.date)}
    
    var body: some View {
        Group {
            if dates.count == 1 {
                Text(formatTime(date: dates.first))
            } else if dates.count == 2 {
                twoDateView(dates: dates)
            } else if dates.count == 3 {
                threeDateView(dates: dates)
            }
        }
        .overlay {eventInfoView(event: event)
        }
    }
    
    private func eventInfoView(event: UserEvent) -> some View {
        Text("\(event.type.description.emoji ?? "") \(event.type.description.label)")
            .font(.body(16, .medium))
            .offset(y: -28)
    }

    private func twoDateView(dates: [Date]) -> some View {
        Text(
            "\(formatTime(date: dates.first, withHour: false, wideWeek: false)) | " +
            "\(formatTime(date: dates[1], withHour: false, wideWeek: false)) · " +
            "\(formatTime(date: dates.first, onlyHour: true))"
        )
    }
    
    private func threeDateView(dates: [Date]) -> some View {
        let dayText = dates
            .map { formatTime(date: $0, withHour: false, wideWeek: false) }
            .joined(separator: ", ")
        
        return Text("\(dayText) · \(formatTime(date: dates[0], onlyHour: true))")
    }
}
    
