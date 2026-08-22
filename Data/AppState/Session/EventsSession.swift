//
//  EventsSession.swift
//  Scoop
//
//  Created by Art Ostin on 02/05/2026.
//

import SwiftUI

//Logic dealing with the User's Events
extension Session {
    
    //1. Listens to all user events where status is pending, accepted, or past accepted
    func eventsStream() {
        subscribe("events", to: eventsRepo.eventTracker(userId: user.id)) { [weak self] change in
            guard let self else { return }
            switch change {
            case .initial(let events): try await self.handleInitial(events)
            case .added(let event):    try await self.handleAdded(event)
            case .modified(let event): try await self.handleModified(event)
            case .removed(let id): self.removeSentInvite(id: id) ; self.removeEvent(id: id)
            }
        }
    }
    
    //2. On initial launch populates all the users sent invites, invites, events and past events
    private func handleInitial(_ events: [UserEvent]) async throws {
        async let sent = profileLoader.fromEvents(events.filter(\.isLiveSentInvite))
        async let inv  = profileLoader.fromEvents(events.filter { $0.status == .pending && $0.role == .received })
        async let acc  = profileLoader.fromEvents(events.filter { $0.status == .accepted })
        async let past = profileLoader.fromEvents(events.filter { $0.status == .pastAccepted })
        setInitialEvents(sent: try await sent, invites: try await inv, active: try await acc, past: try await past)
    }
    
    //3. A new pending event lands in whichever bucket its role names
    private func handleAdded(_ event: UserEvent) async throws {
        guard event.status == .pending else { return }
        let loaded = try await profileLoader.fromEvents([event])
        switch event.role {
        case .received: appendInvites(loaded)
        case .sent:     appendSentInvites(loaded)
        }
    }
    
    //4. Function called if event modified at all. When user accepts invite when session active or new message, this is triggered
    private func handleModified(_ event: UserEvent) async throws {
        try await syncSentInvite(event)
        switch event.status {
        case .accepted:     acceptInvite(eventId: event.id)
        case .pastAccepted: archiveEvent(eventId: event.id)
        default: break
        }
        //Messages updated
        updateEvent(event)
    }
    
    //4a. Sent invites only ever cross this bucket's edge on .modified: accepting flips the status,
    //and either side proposing a new time flips `role` while the status stays .pending. Nothing
    //changes one in place, so only a crossing is worth acting on.
    private func syncSentInvite(_ event: UserEvent) async throws {
        let isPendingSent = event.status == .pending && event.role == .sent
        let held = sentInvites.contains { $0.event.id == event.id }
        guard held != isPendingSent else { return }

        //It left: they accepted, or they proposed a new time and it's their invite again.
        if held {
            removeSentInvite(id: event.id)
            return
        }

        //It arrived: we proposed a new time, so their invite is now ours. The profile and photo are
        //already loaded on the invite we replied to — reuse them instead of refetching.
        if let known = invites.first(where: { $0.event.id == event.id }) {
            appendSentInvites([EventProfile(event: event, profile: known.profile, image: known.image)])
        } else {
            appendSentInvites(try await profileLoader.fromEvents([event]))
        }
    }
}
