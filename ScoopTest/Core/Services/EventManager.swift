//
//  EventManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

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
    
    private func eventDocument(id: String) -> DocumentReference {
        eventCollection.document(id)
    }
    
    private func fetchEvent(eventId: String) async throws -> Event {
        try await eventDocument(id: eventId).getDocument(as: Event.self)
    }
    
    private func fetchUserEvent(userId: String, userEventId: String) async throws -> UserEvent {
       try await userEventDocument(userId: userId, userEventId: userEventId).getDocument(as: UserEvent.self)
    }
    
    
    func createEvent(event: Event, currentUser: UserProfile) async throws {
        let db = Firestore.firestore()
        let batch = db.batch()
        let eventRef = db.collection("events").document()
        let eventId = eventRef.documentID
        guard let recipientId = event.recipientId else { return }
        var e = event
        e.id = eventId
        e.initiatorId = currentUser.id
                
        let recipientProfile = try await userManager.fetchUser(userId: recipientId)
        let recipientName = recipientProfile.name
        let recipientImageString = recipientProfile.imagePathURL.first ?? ""
        
        let inviterName = currentUser.name
        let inviterImageString = currentUser.imagePathURL.first ?? ""
        
        var eventData: [String: Any] = [
            Event.CodingKeys.id.stringValue: eventId,
            Event.CodingKeys.initiatorId.stringValue: currentUser.id,
            Event.CodingKeys.recipientId.stringValue: recipientId,
            Event.CodingKeys.type.stringValue: e.type ?? "",
            Event.CodingKeys.message.stringValue: e.message ?? "",
            Event.CodingKeys.status.stringValue: e.status.rawValue,
            Event.CodingKeys.date_created.stringValue: FieldValue.serverTimestamp()
        ]
        
        if let t = e.time { eventData[Event.CodingKeys.time.stringValue] = t }
        if let loc = e.location {
            let place = try Firestore.Encoder().encode(loc)
            eventData[Event.CodingKeys.location.stringValue] = place
        }
        
        func edgeData(otherUserId: String, role: EdgeRole, otherName: String, otherPhoto: String?) throws -> [String: Any] {
            var data: [String: Any] = [
                UserEvent.CodingKeys.id.rawValue: eventId,
                UserEvent.CodingKeys.otherUserId.rawValue: otherUserId,
                UserEvent.CodingKeys.role.rawValue: role.rawValue,
                UserEvent.CodingKeys.status.rawValue: e.status.rawValue,
                UserEvent.CodingKeys.type.rawValue: e.type ?? "",
                UserEvent.CodingKeys.message.rawValue: e.message ?? "",
                UserEvent.CodingKeys.otherUserName.rawValue: otherName,
                UserEvent.CodingKeys.otherUserPhoto.rawValue: otherPhoto ?? "",
                UserEvent.CodingKeys.updatedAt.rawValue: FieldValue.serverTimestamp()
            ]
            if let t = e.time { data[UserEvent.CodingKeys.time.rawValue] = t }
            if let p = e.location {
                let place = try Firestore.Encoder().encode(p)
                data[UserEvent.CodingKeys.place.rawValue] = place
            }
            if let photo = otherPhoto {
                data[UserEvent.CodingKeys.otherUserPhoto.rawValue] = photo
            }
            return data
        }
        
        let initiatorEdgeRef = db.collection("users").document(currentUser.id)
            .collection("user_events").document(eventId)
        let recipientEdgeRef = db.collection("users").document(recipientId)
            .collection("user_events").document(eventId)
        
        let edgeA = try edgeData(otherUserId: recipientId, role: .sent, otherName: recipientName, otherPhoto: recipientImageString)
        let edgeB = try edgeData(otherUserId: currentUser.id, role: .received, otherName: inviterName, otherPhoto: inviterImageString)
        
        batch.setData(eventData, forDocument: eventRef)
        batch.setData(edgeA, forDocument: initiatorEdgeRef)
        batch.setData(edgeB, forDocument: recipientEdgeRef)
        
        try await batch.commit()
        print("Event Created")
    }
    
    private func eventsQuery(_ scope: EventScope, now: Date = .init(), userId: String) throws -> Query {
    
    let plus3h = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
    switch scope {
    case .upcomingInvited:
        return userEventCollection(userId: userId)
            .whereField(UserEvent.CodingKeys.time.stringValue, isGreaterThan: Timestamp(date: Date()))
            .whereField(UserEvent.CodingKeys.role.rawValue, isEqualTo: EdgeRole.received.rawValue)
            .whereField(UserEvent.CodingKeys.status.rawValue, isEqualTo: EventStatus.pending.rawValue)
            .order(by: Event.CodingKeys.time.stringValue)
    case .upcomingAccepted:
        return userEventCollection(userId: userId)
            .whereField(UserEvent.CodingKeys.time.stringValue, isGreaterThan: Timestamp(date: plus3h))
            .whereField(UserEvent.CodingKeys.status.rawValue, isEqualTo: EventStatus.accepted.rawValue)
            .order(by: Event.CodingKeys.time.stringValue)
        
    case .pastAccepted:
        return userEventCollection(userId: userId)
            .whereField(UserEvent.CodingKeys.status.stringValue, isEqualTo: EventStatus.accepted.rawValue)
            .whereField(UserEvent.CodingKeys.time.stringValue, isLessThan: Timestamp(date: plus3h))
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
        guard let a = ev.initiatorId, let b = ev.recipientId else { return }
        let eventRef = eventDocument(id: eventId)
        let aEdgeRef = userEventDocument(userId: a, userEventId: eventId)
        let bEdgeRef = userEventDocument(userId: b, userEventId: eventId)
        
        
        batch.updateData([Event.CodingKeys.time.stringValue : newTime], forDocument: eventRef)
        let edgeTimeUpdate: [String: Any] = ([
            UserEvent.CodingKeys.time.rawValue : newTime,
            UserEvent.CodingKeys.updatedAt.rawValue : FieldValue.serverTimestamp()])
        
        batch.updateData(edgeTimeUpdate, forDocument: aEdgeRef)
        batch.updateData(edgeTimeUpdate, forDocument: bEdgeRef)
        
        try await batch.commit()
    }
    
    func updateStatus(eventId: String, to newStatus: EventStatus) async throws {
        
        let batch = Firestore.firestore().batch()
        
        let ev = try await fetchEvent(eventId: eventId)
        
        let eventRef = eventDocument(id: eventId)
        guard let a = ev.initiatorId, let b = ev.recipientId else { return }
        let aEdgeRef = userEventDocument(userId: a, userEventId: eventId)
        let bEdgeRef = userEventDocument(userId: b, userEventId: eventId)
        
        batch.updateData([Event.CodingKeys.status.stringValue: newStatus.rawValue], forDocument: eventRef)
        
        let statusUpdate: [String : Any] =  ([
            UserEvent.CodingKeys.status.rawValue : newStatus.rawValue,
            UserEvent.CodingKeys.updatedAt.rawValue : FieldValue.serverTimestamp()])
        
        batch.updateData(statusUpdate, forDocument: aEdgeRef)
        batch.updateData(statusUpdate, forDocument: bEdgeRef)
        try await batch.commit()
    }
    
    
    
    func invitesStream(userId: String) -> AsyncThrowingStream<Event, Error> {
        AsyncThrowingStream { continuation in
            userEventCollection(userId: userId).addSnapshotListener { snapshot, error in
                if let error = error { continuation.finish(throwing: error) ; return }
                
                
                
                
                
            }
        }
    }
}


extension Query {
    func getDocuments<T>(as: T.Type) async throws -> [T] where T: Decodable {
        let snapshot = try await self.getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self)}
    }
}
