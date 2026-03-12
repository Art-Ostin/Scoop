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

class EventsRepo {
    
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
        try fs.set(userEventPath(userId: user.id, userEventId: id), value: initiatorUserEvent, merge: false)
        try fs.set(userEventPath(userId: profile.id, userEventId: id), value: recipientUserEvent, merge: false)
    }
    
    func acceptEvent(eventId: String, acceptedDate: Date) async throws {
        let (event, initiatorId, recipientId) = try await getEventInfo(eventId: eventId)
                        
        var userFields: [String : Any] = [
            Event.Field.status.rawValue : Event.EventStatus.accepted.rawValue,
            Event.Field.acceptedTime.rawValue: acceptedDate
        ]
        let eventFields = userFields
        userFields[UserEvent.Field.userEventChatState.rawValue] = UserEventChatState()
        try await updateEvent(initiatorId: initiatorId, recipientId: recipientId, eventId: eventId, userFields: userFields, eventFields: eventFields)
        
        //Overlapping interest, but avoids more complexity elsewhere
        let chatModel = ChatModel(participantIds: [event.initiatorId, event.recipientId], lastMessageAt: nil)
        try fs.set("chats/\(eventId)", value: chatModel, merge: false)
    }
    
    func updateEventStatus(eventId: String, to newStatus: Event.EventStatus) async throws {
        let (_, initiatorId, recipientId) = try await getEventInfo(eventId: eventId)
        let fields: [String: Any] = [Event.Field.status.rawValue: newStatus.rawValue]
        try await updateEvent(initiatorId: initiatorId, recipientId: recipientId, eventId: eventId, userFields: fields, eventFields: fields)
    }
    
    private func updateEvent(initiatorId: String, recipientId: String, eventId: String, userFields: [String : Any], eventFields: [String : Any]) async throws {
        async let updateInitiator: Void = fs.update(userEventPath(userId: initiatorId, userEventId: eventId), fields: userFields)
        async let updateRecipient: Void = fs.update(userEventPath(userId: recipientId, userEventId: eventId), fields: userFields)
        async let updateEvent: Void = fs.update(EventPath(eventId: eventId) , fields: eventFields)
        _ = try await (updateInitiator, updateRecipient, updateEvent)
    }

    private func getEventInfo(eventId: String) async throws -> (event: Event, initiatorId: String, recipientId: String) {
        let event = try await fetchEvent(eventId: eventId), initiatorId = event.initiatorId, recipientId = event.recipientId
        return(event, initiatorId, recipientId)
    }
    
    //Part 3:Track Events
    func eventTracker(userId: String) -> AsyncThrowingStream<FSCollectionEvent<UserEvent>, Error> {
        //Set up the listener for specifically the UserEvents. Only includes events pending, accepted, or pastAccepted
        let userEventsPath = "users/\(userId)/user_events"
        let statuses = [
            Event.EventStatus.pending.rawValue,
            Event.EventStatus.accepted.rawValue,
            Event.EventStatus.pastAccepted.rawValue
        ]
        return fs.streamCollection(userEventsPath) {$0.whereField(Event.Field.status.rawValue,in: statuses)}
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




//Logic to fetch initial events from the collection (I think wrong logic)
/*
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
 */


