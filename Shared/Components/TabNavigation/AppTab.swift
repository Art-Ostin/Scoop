//
//  TabBarItem.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import Foundation
import SwiftUI

enum AppTab: Hashable, CaseIterable, Identifiable {
    
    case meet, invites, events, messages
    
    var id: Self { self }
    
    // Native (iOS 26+) tab bar icons.
    func nativeIcon(selected: Bool) -> String {
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
    // Custom tab bar (iOS<26) icons.
    func customIcon(selected: Bool) -> Image {
        switch (self, selected) {
        case (.meet,       true):  Image("AppLogoApp")
        case (.meet,       false): Image("AppLogoBlack")
        case (.invites,    true):  Image("TabLetterGray")
        case (.invites,    false): Image("TabLetterBlack")
        case (.events,     true):  Image("EventApp")
        case (.events,     false): Image("EventIcon")
        case (.messages, true):  Image("MessageApp")
        case (.messages, false): Image("MessageIcon")
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
    
    func title() -> some View {
        
    }
}
