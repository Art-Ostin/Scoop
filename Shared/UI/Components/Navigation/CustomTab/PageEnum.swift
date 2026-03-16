//
//  PageEnum.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import Foundation

enum Page: String, Hashable {
    
    case meet, match, meetingNoEvent, meetingEvent, message, editProfile
    
    var title: String {
        switch self {
        case .meetingEvent, .meetingNoEvent:
            return "Meeting"
        case .editProfile:
            return "Edit Profile"
        default:
            return self.rawValue.capitalized
        }
    }
}

