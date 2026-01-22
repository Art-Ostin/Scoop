//
//  FormatTimeAndPlace.swift
//  Scoop
//
//  Created by Art Ostin on 21/01/2026.
//

import SwiftUI

struct FormatTimeAndPlace: View {
    
    let time: Date
    let place: EventLocation
    
    var body: some View {
        (
            Text("\(formattedDate(from: time))\n") +
            Text(place.name ?? " ")
                .foregroundStyle(.accent)
        )
        .font(.body(24, .bold))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .lineSpacing(14)
    }
}

func formattedDate(from date: Date) -> String {
    let dayPart = date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    let timePart = date.formatted(.dateTime.hour().minute())
    return "\(dayPart) · \(timePart)"
}



/*
 private var formattedDate: String {
     let df = DateFormatter()
     df.timeZone = .current
     df.dateFormat = "EEEE, MMM d · HH:mm"
     return df.string(from: time)
 }
 

 */
