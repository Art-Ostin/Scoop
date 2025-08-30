//
//  EventManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

enum UserEventUpdate {
    case eventInvite(userEvent: UserEvent)
    case removeInvite(id: String)
    case eventAccepted(userEvent: UserEvent)
    case pastEventAccepted(userEvent: UserEvent)
}


class EventManager {

    private let userManager: UserManager
    
    init(userManager: UserManager) { self.userManager = userManager }
    
    private let eventCollection = Firestore.firestore().collection("events")
    private let userCollection = Firestore.firestore().collection("users")
    
    private func userEventCollection (userId: String) -> CollectionReference {
        userCollection.document(userId).collection("user_events")
    }
    
    private func userEventDocument (userId: String, userEventId: String) -> DocumentReference {
        userEventCollection(userId: userId).document(userEventId)
    }
    
    private func eventDocument(eventId: String) -> DocumentReference {
        eventCollection.document(eventId)
    }
    
    private func fetchEvent(eventId: String) async throws -> Event {
        try await eventDocument(eventId: eventId).getDocument(as: Event.self)
    }
    
    private func fetchUserEvent(userId: String, userEventId: String) async throws -> UserEvent {
        try await userEventDocument(userId: userId, userEventId: userEventId).getDocument(as: UserEvent.self)
    }
    
    func createEvent(draft: EventDraft, user: UserProfile, profile: UserProfile) async throws {
        var draft = draft
        
        draft.initiatorId = user.id
        draft.recipientId = profile.id
        draft.inviteExpiryTime = getEventExpiryTime(draft: draft)
        
        let event = Event(draft: draft)
        
        let ref = try eventCollection.addDocument(from: event)
        let id = ref.documentID
        
        let initiatorUserEvent = makeUserEvent(profile: profile, role: .sent, event: event)
        let recipientUserEvent = makeUserEvent(profile: user, role: .received, event: event)
        
        try userEventCollection(userId: user.id).document(id).setData(from: initiatorUserEvent)
        try userEventCollection(userId: profile.id).document(id).setData(from: recipientUserEvent)

    }
    
    func makeUserEvent(profile: UserProfile, role: EdgeRole, event: Event) -> UserEvent  {
        UserEvent(otherUserId: profile.id, role: role, status: event.status, time: event.time, type: event.type, message: event.message, place: event.location, otherUserName: profile.name , otherUserPhoto: profile.imagePathURL.first ?? "", updatedAt: nil, inviteExpiryTime: event.inviteExpiryTime)
    }
    
    
    
    func getEventExpiryTime(draft: EventDraft) -> Date? {
        guard let eventTime = draft.time else {return nil}
        
        let timeUntilEvent = eventTime.timeIntervalSince(Date())
        
        let day: TimeInterval = 24*3600
        let hour: TimeInterval = 3600
        
        if  timeUntilEvent > TimeInterval(2*day + 8*hour) {
            return Date().addingTimeInterval(2 * day)
        } else if  timeUntilEvent > TimeInterval(day + 8*hour) {
            return Date().addingTimeInterval(day)
        } else if timeUntilEvent > TimeInterval(14*hour)  {
            return Calendar.current.date(byAdding: .hour, value: -6, to: eventTime)
        } else if timeUntilEvent > TimeInterval(8*hour) {
            return Calendar.current.date(byAdding: .hour, value: -1, to: eventTime)
        } else {
            return eventTime
        }
    }
    
    
    
    
    
    private func eventsQuery(_ scope: EventScope, now: Date = .init(), userId: String) throws -> Query {

        let plus3h = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
        switch scope {
        case .upcomingInvited:
            return userEventCollection(userId: userId)
                .whereField(UserEvent.Field.time.rawValue, isGreaterThan: Timestamp(date: Date()))
                .whereField(UserEvent.Field.role.rawValue, isEqualTo: EdgeRole.received.rawValue)
                .whereField(UserEvent.Field.status.rawValue, isEqualTo: EventStatus.pending.rawValue)
                .order(by: Event.Field.time.rawValue)
        case .upcomingAccepted:
            return userEventCollection(userId: userId)
                .whereField(UserEvent.Field.time.rawValue, isGreaterThan: Timestamp(date: plus3h))
                .whereField(UserEvent.Field.status.rawValue, isEqualTo: EventStatus.accepted.rawValue)
                .order(by: Event.Field.time.rawValue)
            
        case .pastAccepted:
            return userEventCollection(userId: userId)
                .whereField(UserEvent.Field.status.rawValue, isEqualTo: EventStatus.accepted.rawValue)
                .whereField(UserEvent.Field.time.rawValue, isLessThan: Timestamp(date: plus3h))
        }
    }
    
    private func getEvents(_ scope: EventScope, now: Date = .init(), userId: String) async throws -> [UserEvent] {
        let query = try eventsQuery(scope, now: now, userId: userId)
        return try await query
            .getDocuments(as: UserEvent.self)
    }
    
    func getUpcomingAcceptedEvents(userId: String) async throws -> [UserEvent] {
        try await getEvents(.upcomingAccepted, userId: userId)
    }
    
    func getUpcomingInvitedEvents(userId: String) async throws -> [UserEvent] {
        try await getEvents(.upcomingInvited, userId: userId)
    }
    
    func getPastAcceptedEvents(userId: String) async throws -> [UserEvent] {
        try await getEvents(.pastAccepted, userId: userId)
    }
    
    func updateTime(eventId: String, to newTime: Date) async throws {
        let batch = Firestore.firestore().batch()
        
        let ev = try await fetchEvent(eventId: eventId)
        let eventRef = eventDocument(eventId: eventId)
        let aEdgeRef = userEventDocument(userId: ev.initiatorId, userEventId: eventId)
        let bEdgeRef = userEventDocument(userId: ev.recipientId, userEventId: eventId)
        
        
        batch.updateData([Event.Field.time.rawValue : newTime], forDocument: eventRef)
        let edgeTimeUpdate: [String: Any] = ([
            UserEvent.Field.time.rawValue : newTime,
            UserEvent.Field.updatedAt.rawValue : FieldValue.serverTimestamp()])
        
        batch.updateData(edgeTimeUpdate, forDocument: aEdgeRef)
        batch.updateData(edgeTimeUpdate, forDocument: bEdgeRef)
        
        try await batch.commit()
    }
    
    func updateStatus(eventId: String, to newStatus: EventStatus) async throws {
        let batch = Firestore.firestore().batch()
        let ev = try await fetchEvent(eventId: eventId)
        
        let eventRef = eventDocument(eventId: eventId)
        let aEdgeRef = userEventDocument(userId: ev.initiatorId, userEventId: eventId)
        let bEdgeRef = userEventDocument(userId: ev.recipientId, userEventId: eventId)
        
        batch.updateData([Event.Field.status.rawValue: newStatus.rawValue], forDocument: eventRef)
        
        let statusUpdate: [String : Any] =  ([
            UserEvent.Field.status.rawValue : newStatus.rawValue,
            UserEvent.Field.updatedAt.rawValue : FieldValue.serverTimestamp()])
        
        batch.updateData(statusUpdate, forDocument: aEdgeRef)
        batch.updateData(statusUpdate, forDocument: bEdgeRef)
        try await batch.commit()
    }
    
    
    func eventStream(userId: String) -> AsyncThrowingStream<UserEventUpdate, Error> {
        AsyncThrowingStream { continuation in
            let reg = userEventCollection(userId: userId).addSnapshotListener { snapshot, error in
                if let error = error { continuation.finish(throwing: error) ; return }
                guard let snap = snapshot else { return }
                
                for change in snap.documentChanges {
                    switch change.type {
                        
                    case .modified, .added:
                        guard let ue = try? change.document.data(as: UserEvent.self) else { continue }
                        switch ue.status {
                        case .pending: continuation.yield(.eventInvite(userEvent: ue))
                        case .accepted: continuation.yield(.eventAccepted(userEvent: ue))
                        case .pastAccepted: continuation.yield(.pastEventAccepted(userEvent: ue))
                        default : continuation.yield(.removeInvite(id: ue.otherUserId))
                        }
                        
                    case .removed:
                        break
                    }
                }
            }
            continuation.onTermination = { _ in reg.remove() }
        }
    }
}


extension Query {
    func getDocuments<T>(as: T.Type) async throws -> [T] where T: Decodable {
        let snapshot = try await self.getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self)}
    }
}
