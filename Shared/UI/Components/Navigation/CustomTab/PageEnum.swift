//
//  PageEnum.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import Foundation

enum Page: String, Hashable {
    
    case meet, invites, meetingNoEvent, meetingEvent, pastMatches, editProfile
    
    var title: String {
        switch self {
        case .meetingEvent, .meetingNoEvent:
            return "Meeting"
        case .editProfile:
            return "Edit Profile"
        case .pastMatches:
            return "Message"
        default:
            return self.rawValue.capitalized
        }
    }
}
