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
    
    private var formattedDate: String {
        let df = DateFormatter()
        df.timeZone = .current
        df.dateFormat = "EEEE, MMM d · HH:mm"
        return df.string(from: time)
    }
    
    var body: some View {
        (
            Text("\(formattedDate)\n") +
            Text(place.name ?? " ")
                .foregroundStyle(.accent)
        )
        .font(.body(24, .bold))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .lineSpacing(14)
    }
}
