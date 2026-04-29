//
//  eventRepo.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation
import FirebaseFirestore

enum EventsRepoError: Error {
    case invalidDraft
}

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
    func createEvent(draft: EventFieldsDraft, user: UserProfile, profile: UserProfile) async throws {
        //1. Create the event, and add it to the collection 'events'
        guard let event = Event(draft: draft, initiatorId: user.id, recipientId: profile.id) else {
            throw EventsRepoError.invalidDraft
        }
        let id = try fs.add("events", value: event)
        
        //2 Create the two UserEvents
        let initiatorUserEvent = UserEvent(otherProfile: profile, role: .sent, event: event)
        let recipientUserEvent = UserEvent(otherProfile: user, role: .received, event: event)
        
        //3. Update the event Paths
        try fs.set(userEventPath(userId: user.id, userEventId: id), value: initiatorUserEvent, merge: false)
        try fs.set(userEventPath(userId: profile.id, userEventId: id), value: recipientUserEvent, merge: false)
    }
        
    func updateEventStatus(eventId: String, to newStatus: Event.EventStatus) async throws {
        let (_, initiatorId, recipientId) = try await getEventInfo(eventId: eventId)
        let fields: [String: Any] = [Event.Field.status.rawValue: newStatus.rawValue]
        
        try await updateEvent(initId: initiatorId, recipId: recipientId, eventId: eventId, initFields: fields, recipFields: fields, eventFields: fields)
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
        return fs.streamCollection(userEventsPath) {$0.whereField(Event.Field.status.rawValue, in: statuses)}
    }
    
    //Streams MessagePopupModel events for incoming messages from the other user.
    //Filters out doc updates where chatState didn't change (status/location/etc. edits don't trigger a popup).
    func eventMessageTracker(userId: String) -> AsyncThrowingStream<FSCollectionEvent<MessagePopupModel>, Error> {
        let userEventPath = "users/\(userId)/user_events"
        let source: AsyncThrowingStream<FSCollectionEvent<UserEvent>, Error> = fs.streamCollection(userEventPath) {
            $0.whereField(self.chatStateField(.lastMessageAuthor), isNotEqualTo: userId)
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                var lastSeenAt: [String: Date] = [:]
                do {
                    for try await change in source {
                        switch change {
                        case .initial(let events):
                            //1. Fetches and stores all the 'lastSeenAt' events times
                            for ue in events {
                                if let at = ue.chatState?.lastMessageAt { lastSeenAt[ue.id] = at }
                            }
                        case .added(let ue):
                            //Stores the lastSeent at time when added, then adds the messagePopup
                            if let at = ue.chatState?.lastMessageAt { lastSeenAt[ue.id] = at }
                            if let popup = ue.messagePopup { continuation.yield(.added(popup)) }

                        case .modified(let ue):
                            //Only adds the message, if 'lastAdded' changes/Updates.
                            let newAt = ue.chatState?.lastMessageAt
                            guard newAt != lastSeenAt[ue.id] else { continue }
                            lastSeenAt[ue.id] = newAt
                            if let popup = ue.messagePopup { continuation.yield(.modified(popup)) }

                        case .removed(let id):
                            lastSeenAt.removeValue(forKey: id)
                            continuation.yield(.removed(id: id))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    
    //To get a specific ChatField
    func chatStateField(_ field: ChatState.Field) -> String {
        return "\(UserEvent.Field.chatState.rawValue).\(field.rawValue)"
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

//Logic regarding responding with (1) Accepting Event (2) Declining Invite (3) Sending New Times (4) Sending New Event.
extension EventsRepo {
    
    func acceptEvent(eventId: String, senderId: String, userId: String, acceptedTime: Date) async throws {
        var userFields: [String : Any] = [
            Event.Field.status.rawValue : Event.EventStatus.accepted.rawValue,
            Event.Field.acceptedTime.rawValue: acceptedTime
        ]
        let eventFields = userFields
        userFields[UserEvent.Field.chatState.rawValue] = try fs.encodeFields(ChatState())
        try await updateEvent(initId: senderId, recipId: userId, eventId: eventId, initFields: userFields, recipFields: userFields, eventFields: eventFields)
        //Chat Model
        let chatModel = ChatModel(participantIds: [senderId, userId], lastMessageAt: nil)
        try fs.set("chats/\(eventId)", value: chatModel, merge: false)
    }
    
    func declineEvent(eventId: String, otherUserId: String, userId: String) async throws {
        let updatedField: [String: Any] = [
            UserEvent.Field.status.rawValue : Event.EventStatus.declined.rawValue
        ]
        try await updateEvent(initId: otherUserId, recipId: userId, eventId: eventId, initFields: updatedField, recipFields: updatedField, eventFields: updatedField)
    }
    
    func respondWithNewTime(newTime: RescheduleResponse) async throws {
        //1.Reverse who is initiator and who is recipient
        let newInitiatorId = newTime.userId
        
        //2: With the old and new times generate an 'update Log' data
        let encodedTimes = try fs.encodeFields(newTime.newTimes)
        let encodedChangeLog = try changeLogEntryTime(oldTimes: newTime.oldTimes, newTimes: newTime.newTimes, userUpdating: newTime.userId)
        
        
        //3. Construct fields to update for UserFields and Event
        let newInitiatorFields: [String : Any] = [
            UserEvent.Field.proposedTimes.rawValue: encodedTimes,
            UserEvent.Field.role.rawValue: UserEvent.EdgeRole.sent.rawValue
        ]
        let newRecipientFields: [String : Any] = [
            UserEvent.Field.proposedTimes.rawValue: encodedTimes,
            UserEvent.Field.role.rawValue: UserEvent.EdgeRole.received.rawValue
        ]
        let eventFields: [String : Any] = [
            Event.Field.proposedTimes.rawValue: encodedTimes,
            Event.Field.initiatorId.rawValue: newInitiatorId,
            Event.Field.recipientId.rawValue: newTime.recipientId,
            Event.Field.changeLog.rawValue: FieldValue.arrayUnion([encodedChangeLog])
        ]
        //4. Now with the updated Fields created, now update the event
        try await updateEvent(
            initId: newInitiatorId,
            recipId: newTime.recipientId,
            eventId: newTime.eventId,
            initFields: newInitiatorFields,
            recipFields: newRecipientFields,
            eventFields: eventFields
        )
    }
    
    func respondWithNewEvent(eventResponse: EventResponse) async throws {
        //1.Reverse who is initiator and who is recipient
        let newInitiatorId = eventResponse.userId
        let newRecipientId = eventResponse.otherUserId
        
        //2. Encode proposedTimes so can be uploaded to Firebase
        let encodedTimes = try fs.encodeFields(eventResponse.newTimes)
        let encodedLocation = try fs.encodeFields(eventResponse.newPlace)
        
        //3. Get the core fields that update for both users
        let coreFields: [String: Any] = [
            UserEvent.Field.proposedTimes.rawValue: encodedTimes,
            UserEvent.Field.location.rawValue: encodedLocation,
            UserEvent.Field.type.rawValue: eventResponse.newType.rawValue,
        ]
        
        //4. Update the respective fields for User
        var newInitiatorFields = coreFields
        newInitiatorFields[UserEvent.Field.role.rawValue] = UserEvent.EdgeRole.sent.rawValue
        
        var newRecipientFields = coreFields
        newRecipientFields[UserEvent.Field.role.rawValue] = UserEvent.EdgeRole.received.rawValue

        //5. Create the change log and create the event Fields
        let encodedChangeLog = try changeLogEntryEvent(eventResponse: eventResponse)
        
        var eventFields = coreFields
        eventFields[Event.Field.changeLog.rawValue] = FieldValue.arrayUnion([encodedChangeLog])
        
        //6. Now update the status of the event.
        try await updateEvent(
            initId: newInitiatorId,
            recipId: newRecipientId,
            eventId: eventResponse.eventId,
            initFields: newInitiatorFields,
            recipFields: newRecipientFields,
            eventFields: eventFields
        )
    }
}
  

//Helpers for function
extension EventsRepo {
    
    private func updateEvent(
        initId: String,
        recipId: String,
        eventId: String,
        initFields: [String: Any],
        recipFields: [String: Any],
        eventFields: [String : Any]
    ) async throws {
        async let updateInitiator: Void = fs.update(userEventPath(userId: initId, userEventId: eventId), fields: initFields)
        async let updateRecipient: Void = fs.update(userEventPath(userId: recipId, userEventId: eventId), fields: recipFields)
        async let updateEvent: Void = fs.update(EventPath(eventId: eventId) , fields: eventFields)
        _ = try await (updateInitiator, updateRecipient, updateEvent)
    }
    
    private func getEventInfo(eventId: String) async throws -> (event: Event, initiatorId: String, recipientId: String) {
        let event = try await fetchEvent(eventId: eventId), initiatorId = event.initiatorId, recipientId = event.recipientId
        return(event, initiatorId, recipientId)
    }
    
    private func changeLogEntryTime(oldTimes: ProposedTimes, newTimes: ProposedTimes, userUpdating: String) throws -> [String: Any] {
        //1. Extract the old and New Dates
        let oldTimes: [Date] = oldTimes.dates.map{ $0.date}
        let newTimes: [Date] = newTimes.dates.map{ $0.date}

        //2. Create the 'change Values' for log entry
        let oldTimesChangeValue = ChangeValue.proposedTimes(oldTimes)
        let newTimesChangeValue = ChangeValue.proposedTimes(newTimes)

        //3. Create the ChangeItem (field created for updating Time)
        let changeItem = ChangeItem(changeType: ChangeType.newTime.rawValue, oldValue: oldTimesChangeValue, newValue: newTimesChangeValue)
        
        //4. a. Create the ChangeLogEntry, b. encode it so it can be added to firebase c. return encoded value.
        let changeLog = ChangeLogEntry(editedByUserId: userUpdating, changes: [changeItem])
        return try fs.encodeFields(changeLog)
    }
    
    private func changeLogEntryEvent(eventResponse: EventResponse) throws -> [String: Any] {
        //1. Extract the old and New Dates
        let oldTimes: [Date] = eventResponse.oldTimes.dates.map{ $0.date}
        let newTimes: [Date] = eventResponse.newTimes.dates.map{ $0.date}
        
        let oldType = eventResponse.oldType.rawValue
        let newType = eventResponse.newType.rawValue
        
        let oldPlace = eventResponse.oldPlace.name ?? eventResponse.oldPlace.address ?? ""
        let newPlace = eventResponse.newPlace.name ?? eventResponse.newPlace.address ?? ""
        
        //2. Create the 'Change Values' for log Entry
        let oldTimesChangeValue = ChangeValue.proposedTimes(oldTimes)
        let newTimesChangeValue = ChangeValue.proposedTimes(newTimes)
        let changeItemTime = ChangeItem(changeType: ChangeType.newEvent.rawValue, oldValue: oldTimesChangeValue, newValue: newTimesChangeValue)
        
        let oldTypeValue = ChangeValue.string(oldType)
        let newTypeValue = ChangeValue.string(newType)
        let changeItemType = ChangeItem(changeType: ChangeType.newEvent.rawValue, oldValue: oldTypeValue, newValue: newTypeValue)
        
        let oldPlaceValue = ChangeValue.string(oldPlace)
        let newPlaceValue = ChangeValue.string(newPlace)
        let changeItemPlace = ChangeItem(changeType: ChangeType.newEvent.rawValue, oldValue: oldPlaceValue, newValue: newPlaceValue)
        
        //3. From the registered changeItems, generate the change Log
        let changeLog = ChangeLogEntry(editedByUserId: eventResponse.userId, changes: [changeItemTime, changeItemType, changeItemPlace])
        return try fs.encodeFields(changeLog)
    }
}
