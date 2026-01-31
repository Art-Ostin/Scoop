//
//  EventManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation
import FirebaseFirestore



enum UserEventKind { case invite, accepted, pastAccepted, remove }
typealias UserEventUpdate = (event: UserEvent, kind: UserEventKind)

class EventManager {
    
    private let userManager: UserManager
    private let fs: FirestoreService
    
    init(userManager: UserManager, fs: FirestoreService) { self.userManager = userManager ; self.fs = fs }
    
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
        var draft = draft
        
        draft.initiatorId = user.id
        draft.recipientId = profile.id
        
        let event = Event(draft: draft)
        let id = try fs.add("events", value: event)
        
        let initiatorUserEvent = makeUserEvent(otherProfile: profile, role: .sent, event: event)
        let recipientUserEvent = makeUserEvent(otherProfile: user, role: .received, event: event)
        
        try fs.set(userEventPath(userId: user.id, userEventId: id), value: initiatorUserEvent)
        try fs.set(userEventPath(userId: profile.id, userEventId: id), value: recipientUserEvent)
        
        func makeUserEvent(otherProfile: UserProfile, role: EdgeRole, event: Event) -> UserEvent  {
            UserEvent(
                otherUserId: otherProfile.id,
                role: role, status: event.status,
                proposedTimes: event.proposedTimes,
                type: event.type,
                message: event.message,
                place: event.location,
                otherUserName: otherProfile.name ,
                otherUserPhoto: otherProfile.imagePathURL.first ?? "",
                updatedAt: nil)
        }
    }
        
    func eventTracker(userId: String, now: Date = .init()) async throws -> (initial: [UserEventUpdate], updates: AsyncThrowingStream<UserEventUpdate, Error>) {
        let path = "users/\(userId)/user_events"
        let plus6h = Calendar.current.date(byAdding: .hour, value: 6, to: now)!
        typealias F = UserEvent.Field
        
        let invitedFilters: [FSWhere] = [
            FSWhere(field: F.status.rawValue, op: .eq,  value: EventStatus.pending.rawValue),
            FSWhere(field: F.role.rawValue,   op: .eq,  value: EdgeRole.received.rawValue),
        ]
        
        let upcomingAcceptedFilters: [FSWhere] = [
            FSWhere(field: F.status.rawValue, op: .eq,  value: EventStatus.accepted.rawValue),
            FSWhere(field: F.acceptedTime.rawValue,   op: .gte, value: plus6h),
        ]
        
        let pastAcceptedFilters: [FSWhere] = [
            FSWhere(field: F.status.rawValue, op: .eq, value: EventStatus.accepted.rawValue),
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
        
        let updates = AsyncThrowingStream<UserEventUpdate, Error> { continuation in
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
                            } else if e.status == .accepted {
                                if e.time >= plus6h {
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
    
    func updateStatus(eventId: String, to newStatus: EventStatus) async throws {
        let event = try await fetchEvent(eventId: eventId), initiatorId = event.initiatorId, recipientId = event.recipientId
        try await fs.update(userEventPath(userId: initiatorId, userEventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
        try await fs.update(userEventPath(userId: recipientId, userEventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
        try await fs.update(EventPath(eventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
    }
    
    func cancelEvent(eventId: String, cancelledById: String, blockedContext: BlockedContext) async throws {
        //1. Update the status and specify who cancelled the event
        let event = try await fetchEvent(eventId: eventId)
        let otherUserId = (cancelledById == event.initiatorId) ? event.recipientId : event.initiatorId
        
        try await updateStatus(eventId: eventId, to: .cancelled)
        try await fs.update(EventPath(eventId: eventId), fields: [Event.Field.earlyTerminatorID.rawValue : cancelledById])
        try await fs.update(userEventPath(userId: cancelledById, userEventId: eventId), fields: [Event.Field.earlyTerminatorID.rawValue : cancelledById])
        try await fs.update(userEventPath(userId: otherUserId, userEventId: eventId), fields: [Event.Field.earlyTerminatorID.rawValue : cancelledById])
        print("Succesfully updated Cancelled By user")
        
        //2. Update user profile to a frozen account (by updating/adding to those fields) and adding 1 to cancel Count
        let encodedBlockedContext = try Firestore.Encoder().encode(blockedContext)
        let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        
        try await userManager.updateUser(userId: cancelledById, values: [.blockedContext : encodedBlockedContext] )
        try await userManager.updateUser(userId: cancelledById, values: [.frozenUntil : twoWeeksFromNow] )
        try await userManager.updateUser(userId: cancelledById, values: [.cancelCount: FieldValue.increment(Int64(1))])
        
        //3. Delete all the user's pending invites (actually deletes the files -- as deemed cleanest solution)
        try await deleteAllSentPendingInvites(userId: cancelledById)
    }
    
    func fetchPendingSentInvites(userId: String) async throws -> [UserEvent] {
        let path = "users/\(userId)/user_events"
        typealias F = UserEvent.Field
        
        let pendingSentFilters: [FSWhere] = [
            FSWhere(field: F.status.rawValue, op: .eq, value: EventStatus.pending.rawValue),
            FSWhere(field: F.role.rawValue, op: .eq, value: EdgeRole.sent.rawValue),
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
}


