//
//  PastEventModel.swift
//  Scoop
//
//  Created by Art Ostin on 12/03/2026.
//

import SwiftUI

struct PastEventModel: Identifiable {
    var userEvent: UserEvent
    var profile: UserProfile
    var photo: UIImage?
    
    var recentChatState: UserEventChatState? {
        userEvent.recentChatState
    }
    var id: String {
        userEvent.id ?? profile.id
    }
}
