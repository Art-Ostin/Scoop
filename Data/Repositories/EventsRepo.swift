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
    
    private let fs: FirestoreService
    
    init(fs: FirestoreService) { self.fs = fs}
    
    //PART 1: Setting up Event Paths
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
    
    //Part 2: Creating and modifying events
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
    
    func acceptEvent(eventId: String, acceptedDate: Date) async throws {
        let event = try await fetchEvent(eventId: eventId), initiatorId = event.initiatorId, recipientId = event.recipientId
                
        let eventFields: [String : Any] = [
            Event.Field.status.rawValue : Event.EventStatus.accepted.rawValue,
            Event.Field.acceptedTime.rawValue: acceptedDate
        ]
        
        let userEventFields: [String : Any] = [
            Event.Field.status.rawValue : Event.EventStatus.accepted.rawValue,
            Event.Field.acceptedTime.rawValue: acceptedDate,
            UserEvent.Field.userEventChatState.rawValue : UserEventChatState()
        ]
        
        async let updateInitiator: Void = fs.update(userEventPath(userId: initiatorId, userEventId: event.id), fields: userEventFields)
        async let updateRecipient: Void = fs.update(userEventPath(userId: recipientId, userEventId: event.id), fields: userEventFields)
        async let updateEvent: Void = fs.update(EventPath(eventId: event.id), fields: eventFields)
        _ = try await (updateInitiator, updateRecipient, updateEvent)

        //Overlapping interest, but avoids more complexity elsewhere
        let chatModel = ChatModel(participantIds: [event.initiatorId, event.recipientId], lastMessageAt: nil)
        try fs.set("chats/\(eventId)", value: chatModel)
    }
    
    func updateEventStatus(eventId: String, to newStatus: Event.EventStatus) async throws {
        let event = try await fetchEvent(eventId: eventId), initiatorId = event.initiatorId, recipientId = event.recipientId
        let fields: [String: Any] = [Event.Field.status.rawValue: newStatus.rawValue]
        
        try await fs.update(userEventPath(userId: initiatorId, userEventId: eventId), fields: fields)
        try await fs.update(userEventPath(userId: recipientId, userEventId: eventId), fields: fields)
        try await fs.update(EventPath(eventId: eventId), fields: fields)
    }

    //Part 3:Track Events
    
    func eventTracker(userId: String, now: Date = .init()) async throws -> (initial: [UserEventUpdate], updates: AsyncThrowingStream<UserEventUpdate, Error>) {
        let path = "users/\(userId)/user_events"
        typealias F = UserEvent.Field
        
        //2. Actually fetch the events from the collection
        async let invited: [UserEvent] = fs.fetchFromCollection(path) {
            $0.whereField(F.status.rawValue, isEqualTo: Event.EventStatus.pending.rawValue)
                .whereField(F.role.rawValue, isEqualTo: UserEvent.EdgeRole.received.rawValue)
                .order(by: F.proposedTimes.rawValue, descending: false)
        }
        
        async let upcoming: [UserEvent] = fs.fetchFromCollection(path) {
            $0.whereField(F.status.rawValue, isEqualTo: Event.EventStatus.accepted.rawValue)
                .order(by: F.acceptedTime.rawValue, descending: false)
        }
        
        async let past: [UserEvent] = fs.fetchFromCollection(path) {
            $0.whereField(F.status.rawValue, isEqualTo: Event.EventStatus.pastAccepted.rawValue)
                .order(by: F.acceptedTime.rawValue, descending: true)
        }
        
        let (inv, upc, pas) = try await (invited, upcoming, past)
        
        
        let initial: [UserEventUpdate] =
        inv.map { (event: $0, kind: .invite) }
        + upc.map { (event: $0, kind: .accepted) }
        + pas.map { (event: $0, kind: .pastAccepted) }
        
        let base: AsyncThrowingStream<FSCollectionEvent<UserEvent>, Error> = fs.streamCollection(path)
        
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
                            } else if e.status == .accepted {
                                continuation.yield((event: e, kind: .accepted))
                            } else if e.status == .pastAccepted {
                                continuation.yield((event: e, kind: .pastAccepted))
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
    
    
    
}

//Logic deleting all userEvents when the user cancels an Event (Or if t
extension EventsRepo {
    
    func cancelEvent(eventId: String, cancelledById: String, blockedContext: BlockedContext) async throws {
        //1. Update the status and specify who cancelled the event
        let event = try await fetchEvent(eventId: eventId)
        let otherUserId = (cancelledById == event.initiatorId) ? event.recipientId : event.initiatorId
        
        try await updateEventStatus(eventId: eventId, to: .cancelled)
        try await fs.update(EventPath(eventId: eventId), fields: [Event.Field.earlyTerminatorID.rawValue : cancelledById])
        try await fs.update(userEventPath(userId: cancelledById, userEventId: eventId), fields: [Event.Field.earlyTerminatorID.rawValue : cancelledById])
        try await fs.update(userEventPath(userId: otherUserId, userEventId: eventId), fields: [Event.Field.earlyTerminatorID.rawValue : cancelledById])
        
        //3. Delete all the user's pending invites (actually deletes the files -- as deemed cleanest solution)
        try await deleteAllSentPendingInvites(userId: cancelledById)
    }
    
    private func fetchPendingSentInvites(userId: String) async throws -> [UserEvent] {
        let path = "users/\(userId)/user_events"
        typealias F = UserEvent.Field
        
        return try await fs.fetchFromCollection(path) {
            $0.whereField(F.status.rawValue, isEqualTo: Event.EventStatus.pending.rawValue)
                .whereField(F.role.rawValue, isEqualTo: UserEvent.EdgeRole.sent.rawValue)
        }
    }
    
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

//Logic regarding the 'recentMessageState' in the events
extension EventsRepo {
    
    private func chatStateField(_ field: UserEventChatState.Field) -> String {
        "\(UserEvent.Field.userEventChatState.rawValue).\(field.rawValue)"
    }
    
    private func recentChatFields(message: MessageModel, unreadCount: Any) -> [String: Any] {
        [
            chatStateField(.lastMessageAuthor): message.authorId,
            chatStateField(.lastMessagePreview): String(message.content.prefix(40)),
            chatStateField(.lastMessageAt): FieldValue.serverTimestamp(),
            chatStateField(.unreadCount): unreadCount
        ]
    }

    func updateRecentChat(message: MessageModel, eventId: String) async throws {
        async let updateAuthor: Void = fs.update(
            userEventPath(userId: message.authorId, userEventId: eventId),
            fields: recentChatFields(message: message, unreadCount: 0)
        )
        async let updateRecipient: Void = fs.update(
            userEventPath(userId: message.recipientId, userEventId: eventId),
            fields: recentChatFields(message: message, unreadCount: FieldValue.increment(Int64(1)))
        )
        _ = try await (updateAuthor, updateRecipient)
    }
    
    func readRecentMessages(userId: String, userEventId: String) async throws {
        try await fs.update(
            userEventPath(userId: userId, userEventId: userEventId),
            fields: [chatStateField(.unreadCount): 0]
        )
    }
}
