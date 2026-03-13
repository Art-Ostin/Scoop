//
//  Profile.swift
//  Scoop
//
//  Created by Art Ostin on 12/03/2026.
//

import SwiftUI

//ForAcceptedEvents
struct Profile: Identifiable, Hashable {
    var event: UserEvent
    var profile: UserProfile
    var image: UIImage?
    var id: String { profile.id}
    
    var chatState: ChatState? {
        event.chatState
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }
}
