//
//  AppsRouter.swift
//  Scoop Test
//
//  Created by Art Ostin on 25/05/2026.
//

import SwiftUI

@Observable
class AppRouter {
    var selectedTab: AppTab = .meet
    
    var pastEventsPath = NavigationPath()
    var eventsPath = NavigationPath()
    
    var showMessageScreen: String?
}


extension AppRouter {

    @MainActor
    func handle(_ notification: InAppNotification, session: Session) {
        switch notification {
        case .newMessage(let model):
            openMessage(eventId: model.eventId, session: session)
        }
    }

    @MainActor
    private func openMessage(eventId: String, session: Session) {
        let candidates = session.pastEvents + session.events + session.invites
        guard let eventProfile = candidates.first(where: { $0.id == eventId }) else { return }

        if eventProfile.event.status == .accepted {
            showMessageScreen = eventProfile.id
            selectedTab = .events
        } else {
            pastEventsPath.append(eventProfile)
            selectedTab = .pastEvents
        }
    }
}
