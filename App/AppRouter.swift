//
//  AppsRouter.swift
//  Scoop
//
//  Created by Art Ostin on 25/05/2026.
//

import SwiftUI

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .meet
    
    var eventsPath = NavigationPath()
    var pastEventPath = NavigationPath()
    
    var showMessageScreen: String?
}

extension AppRouter {

    func handle(_ notification: InAppNotification, session: Session) {
        switch notification {
        case .newMessage(let model):
            openMessage(eventId: model.eventId, session: session)
        }
    }

    private func openMessage(eventId: String, session: Session) {
        let candidates = session.pastEvents + session.events + session.invites
        guard let eventProfile = candidates.first(where: { $0.id == eventId }) else { return }

        if eventProfile.event.status == .accepted {
            showMessageScreen = eventProfile.id
            selectedTab = .events
        } else {
            selectedTab = .messages
        }
    }
}
