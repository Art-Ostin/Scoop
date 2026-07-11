//
//  TabBarItem.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import SwiftUI

enum AppTab: String, Hashable {
    
    case meet, invites, events, messages
    
    // Native tab bar icons.
    func tabIcon(selected: Bool) -> String {
        switch (self, selected) {
        case (.meet,       true):  "BlackLogo"
        case (.meet,       false): "AppLogoBlack"
        case (.invites,    true):  "TabLetterBlack"
        case (.invites,    false): "TabLetterGray"
        case (.events,     true):  "EventBlack"
        case (.events,     false): "EventIcon"
        case (.messages, true):  "BlackMessage"
        case (.messages, false): "MessageIcon"
        }
    }
    
    @ViewBuilder
    func placeholderView() -> some View {
        switch self {
        case .meet:
            MeetPlaceholder()
        case .invites:
            InvitesPlaceholder()
        case .events:
            EventsPlaceholder()
        case .messages:
            MessagesPlaceholder()
        }
    }
    
    func title(name: String = "", isEmpty: Bool = true) -> String {
        switch self {
        case .events:
            return isEmpty ? "Events" : "Meeting \(name)"
        default:
            return self.rawValue.capitalized
        }
    }
}
