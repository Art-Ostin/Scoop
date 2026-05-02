//
//  EventsSessionManager.swift
//  Scoop
//
//  Created by Art Ostin on 02/05/2026.
//

import SwiftUI

//Logic dealing with the User's Events
extension SessionManager {
    
    //1. Listens to all user events where status is pending, accepted, or past accepted
    func eventsStream() {
        subscribe("events", to: eventsRepo.eventTracker(userId: user.id)) { [weak self] change in
            guard let self else { return }
            switch change {
            case .initial(let events): try await self.handleInitial(events)
            case .added(let event):    try await self.handleAdded(event)
            case .modified(let event): self.handleModified(event)
            case .removed(let id):     self.removeEvent(id: id)
            }
        }
    }

    //2. On initial launch populates all the users invites, events, and past events for session
    private func handleInitial(_ events: [UserEvent]) async throws {
        async let inv  = profileLoader.fromEvents(events.filter { $0.status == .pending && $0.role == .received })
        async let acc  = profileLoader.fromEvents(events.filter { $0.status == .accepted })
        async let past = profileLoader.fromEvents(events.filter { $0.status == .pastAccepted })
        setInitialEvents(invites: try await inv, active: try await acc, past: try await past)
    }

    //3. If new event added, if its user who received event, add it to invites
    private func handleAdded(_ event: UserEvent) async throws {
        guard event.status == .pending, event.role == .received else { return }
        appendInvites(try await profileLoader.fromEvents([event]))
    }

    //4. Function called if event modified at all. When user accepts invite when session active, this is triggered
    private func handleModified(_ event: UserEvent) {
        switch event.status {
        case .accepted:     acceptInvite(eventId: event.id)
        case .pastAccepted: archiveEvent(eventId: event.id)
        default: break
        }
    }
}
