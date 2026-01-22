//
//  EventDetailFormatter.swift
//  Scoop
//
//  Created by Art Ostin on 21/01/2026.
//

import SwiftUI


struct EventTextFormatter: View {
    
    
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
        return event.place.name ?? ( )
    }
    

    
    var body: some View {
        Text("24 hour time: \(formattedTime)")
    }
}

//#Preview {
//    EventTextFormatter(time: Date(timeIntervalSince1970: 1_704_158_600))
//}
