//
//  eventRepo.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation
import FirebaseFirestore



enum UserEventKind { case invite, accepted, pastAccepted, remove }
typealias UserEventUpdate = (event: UserEvent, kind: UserEventKind)

class EventsRepo: EventsRepository {
    
    private let userRepo: UserRepository
    private let fs: FirestoreService
    
    init(userRepo: UserRepository, fs: FirestoreService) { self.userRepo = userRepo ; self.fs = fs }
    
    private func EventPath(eventId: String) -> String {
        "events/\(eventId)"
    }
    
    private func userEventPath(userId: String, userEventId: String) -> String {
        return "users/\(userId)/user_events/\(userEventId)"
    }
    
    private func fetchEvent(eventId: String) async throws -> Event {
        try await fs.get(EventPath(eventId: eventId))
    }
    
    private func fetchUserEvent(userId: String, userEventId: String) async throws -> UserEvent {
        try await fs.get(userEventPath(userId: userId, userEventId: userEventId))
    }
    
    func createEvent(draft: EventDraft, user: UserProfile, profile: UserProfile) async throws {
        //1. Create the event, and add it to the collection 'events'
        let event = Event(draft: draft)
        let id = try fs.add("events", value: event)
        
        //2 Create the two UserEvents
        let initiatorUserEvent = UserEvent(otherProfile: profile, role: .sent, event: event)
        let recipientUserEvent = UserEvent(otherProfile: user, role: .received, event: event)
        
        //3. Update the event Paths
        try fs.set(userEventPath(userId: user.id, userEventId: id), value: initiatorUserEvent)
        try fs.set(userEventPath(userId: profile.id, userEventId: id), value: recipientUserEvent)
    }
    
    
    func eventTracker(userId: String, now: Date = .init()) async throws -> (initial: [UserEventUpdate], updates: AsyncThrowingStream<UserEventUpdate, Error>) {
        let path = "users/\(userId)/user_events"
        let plus6h = Calendar.current.date(byAdding: .hour, value: 6, to: now)!
        typealias F = UserEvent.Field
        
        let invitedFilters: [FSWhere] = [
            FSWhere(field: F.status.rawValue, op: .eq,  value: Event.EventStatus.pending.rawValue),
            FSWhere(field: F.role.rawValue,   op: .eq,  value: UserEvent.EdgeRole.received.rawValue),
        ]
        
        let upcomingAcceptedFilters: [FSWhere] = [
            FSWhere(field: F.status.rawValue, op: .eq,  value: Event.EventStatus.accepted.rawValue),
            FSWhere(field: F.acceptedTime.rawValue,   op: .gte, value: plus6h),
        ]
        
        let pastAcceptedFilters: [FSWhere] = [
            FSWhere(field: F.status.rawValue, op: .eq, value: Event.EventStatus.accepted.rawValue),
            FSWhere(field: F.acceptedTime.rawValue,   op: .lt, value: plus6h),
        ]
        
        async let invited: [UserEvent] = fs.fetchFromCollection(path, filters: invitedFilters, orderBy: FSOrder(field: F.proposedTimes.rawValue, descending: false), limit: nil)
        
        async let upcoming: [UserEvent] = fs.fetchFromCollection(path, filters: upcomingAcceptedFilters, orderBy: FSOrder(field: F.acceptedTime.rawValue, descending: false), limit: nil)
        
        async let past: [UserEvent] = fs.fetchFromCollection(path, filters: pastAcceptedFilters, orderBy: FSOrder(field: F.acceptedTime.rawValue, descending: true), limit: nil)
        
        let (inv, upc, pas) = try await (invited, upcoming, past)
        
        let initial: [UserEventUpdate] =
            inv.map { (event: $0, kind: .invite) }
          + upc.map { (event: $0, kind: .accepted) }
          + pas.map { (event: $0, kind: .pastAccepted) }
        
        let base: AsyncThrowingStream<FSCollectionEvent<UserEvent>, Error> = fs.streamCollection(path, filters: [], orderBy: nil, limit: nil)
        
        let updates = AsyncThrowingStream<UserEventUpdate, Error> { (continuation: AsyncThrowingStream<UserEventUpdate, Error>.Continuation) in
            Task {
                do {
                    for try await ev in base {
                        switch ev {
                        case .initial:
                            continue
                        case .added(let it), .modified(let it):
                            let e = it.model
                            if e.status == .pending, e.role == .received {
                                continuation.yield((event: e, kind: .invite))
                            } else if e.status == .accepted, let time = e.acceptedTime {
                                if time >= plus6h {
                                    continuation.yield((event: e, kind: .accepted))
                                } else {
                                    continuation.yield((event: e, kind: .pastAccepted))
                                }
                            } else {
                                continuation.yield((event: e, kind: .remove))
                            }
                        case .removed:
                            break
                        }
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
        }
        return (initial, updates)
    }
    
    func updateStatus(eventId: String, to newStatus: Event.EventStatus) async throws {
        let event = try await fetchEvent(eventId: eventId), initiatorId = event.initiatorId, recipientId = event.recipientId
        try await fs.update(userEventPath(userId: initiatorId, userEventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
        try await fs.update(userEventPath(userId: recipientId, userEventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
        try await fs.update(EventPath(eventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
    }
        
    func fetchPendingSentInvites(userId: String) async throws -> [UserEvent] {
        let path = "users/\(userId)/user_events"
        typealias F = UserEvent.Field
        
        let pendingSentFilters: [FSWhere] = [
            FSWhere(field: F.status.rawValue, op: .eq, value: Event.EventStatus.pending.rawValue),
            FSWhere(field: F.role.rawValue, op: .eq, value: UserEvent.EdgeRole.sent.rawValue),
        ]
        return try await fs.fetchFromCollection(path, filters: pendingSentFilters, orderBy: nil, limit: nil)
    }
    
    //Only used when their profile becomes frozen (or blocked) & just remove all their pending invite events.
    private func deleteEvent(eventId: String) async throws {
        let event = try await fetchEvent(eventId: eventId)
        async let deleteEventDoc: Void = fs.delete(EventPath(eventId: eventId))
        async let deleteInitiator: Void = fs.delete(userEventPath(userId: event.initiatorId, userEventId: eventId))
        async let deleteRecipient: Void = fs.delete(userEventPath(userId: event.recipientId, userEventId: eventId))
        _ = try await (deleteEventDoc, deleteInitiator, deleteRecipient)
    }

    func deleteAllSentPendingInvites(userId: String) async throws {
        let events = try await fetchPendingSentInvites(userId: userId)
        let ids = events.compactMap(\.id)
        for eventId in ids {
            try await deleteEvent(eventId: eventId)
        }
    }
    
    //Should move this somewhere else as not pure event handling
    func cancelEvent(eventId: String, cancelledById: String, blockedContext: BlockedContext) async throws {
        //1. Update the status and specify who cancelled the event
        let event = try await fetchEvent(eventId: eventId)
        let otherUserId = (cancelledById == event.initiatorId) ? event.recipientId : event.initiatorId
        
        try await updateStatus(eventId: eventId, to: .cancelled)
        try await fs.update(EventPath(eventId: eventId), fields: [Event.Field.earlyTerminatorID.rawValue : cancelledById])
        try await fs.update(userEventPath(userId: cancelledById, userEventId: eventId), fields: [Event.Field.earlyTerminatorID.rawValue : cancelledById])
        try await fs.update(userEventPath(userId: otherUserId, userEventId: eventId), fields: [Event.Field.earlyTerminatorID.rawValue : cancelledById])
        print("Succesfully updated Cancelled By user")
                
        //3. Delete all the user's pending invites (actually deletes the files -- as deemed cleanest solution)
        try await deleteAllSentPendingInvites(userId: cancelledById)
    }
}

