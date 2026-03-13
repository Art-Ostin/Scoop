//
//  Profile.swift
//  Scoop
//
//  Created by Art Ostin on 12/03/2026.
//

import SwiftUI

//ForAcceptedEvents
struct EventProfile: Identifiable, Hashable {
    var event: UserEvent
    var profile: UserProfile
    var image: UIImage?
    
    var id: String { event.id }
    var status: Event.EventStatus { event.status }
    var chatState: ChatState? {
        event.chatState
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: EventProfile, rhs: EventProfile) -> Bool {
        lhs.id == rhs.id
    }
}
