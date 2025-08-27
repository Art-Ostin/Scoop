//
//  EventManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

//enum InviteUpdate {
//    case accepted, pastAccepted, declined, declinedTime
//}

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
    
    func createEvent(event: Event, user: UserProfile, profile: UserProfile) async throws {
        var e = event
        
        e.initiatorId = user.id
        e.recipientId = profile.id
        
        e.inviteExpiryTime = getEventExpiryTime(event: e)
        
        let ref = try eventCollection.addDocument(from: event)
        let id = ref.documentID
        
        let initiatorUserEvent = makeUserEvent(profile: profile, role: .sent, event: e)
        let recipientUserEvent = makeUserEvent(profile: user, role: .received, event: e)
        
        try userEventCollection(userId: user.id).document(id).setData(from: initiatorUserEvent)
        try userEventCollection(userId: profile.id).document(id).setData(from: recipientUserEvent)
    }
    
    func makeUserEvent(profile: UserProfile, role: EdgeRole, event: Event) -> UserEvent  {
        UserEvent(otherUserId: profile.id, role: role, status: event.status, time: event.time, type: event.type, message: event.message, place: event.location, otherUserName: profile.name , otherUserPhoto: profile.imagePathURL.first, updatedAt: nil, inviteExpiryTime: event.inviteExpiryTime)
    }
    
    func getEventExpiryTime(event: Event) -> Date? {
        guard let eventTime = event.time else {return nil}
        
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
        guard let a = ev.initiatorId, let b = ev.recipientId else { return }
        let eventRef = eventDocument(eventId: eventId)
        let aEdgeRef = userEventDocument(userId: a, userEventId: eventId)
        let bEdgeRef = userEventDocument(userId: b, userEventId: eventId)
        
        
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
        guard let a = ev.initiatorId, let b = ev.recipientId else { return }
        let aEdgeRef = userEventDocument(userId: a, userEventId: eventId)
        let bEdgeRef = userEventDocument(userId: b, userEventId: eventId)
        
        batch.updateData([Event.Field.status.rawValue: newStatus.rawValue], forDocument: eventRef)
        
        let statusUpdate: [String : Any] =  ([
            UserEvent.Field.status.rawValue : newStatus.rawValue,
            UserEvent.Field.updatedAt.rawValue : FieldValue.serverTimestamp()])
        
        batch.updateData(statusUpdate, forDocument: aEdgeRef)
        batch.updateData(statusUpdate, forDocument: bEdgeRef)
        try await batch.commit()
    }
}


extension Query {
    func getDocuments<T>(as: T.Type) async throws -> [T] where T: Decodable {
        let snapshot = try await self.getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self)}
    }
}

/*
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
         Event.Field.id.rawValue: eventId,
         Event.Field.initiatorId.rawValue: currentUser.id,
         Event.Field.recipientId.rawValue: recipientId,
         Event.Field.type.rawValue: e.type ?? "",
         Event.Field.message.rawValue: e.message ?? "",
         Event.Field.status.rawValue: e.status.rawValue,
         Event.Field.date_created.rawValue: FieldValue.serverTimestamp()
     ]
     
     if let t = e.time { eventData[Event.Field.time.rawValue] = t }
     if let loc = e.location {
         let place = try Firestore.Encoder().encode(loc)
         eventData[Event.Field.location.rawValue] = place
     }
     
     func edgeData(otherUserId: String, role: EdgeRole, otherName: String, otherPhoto: String?) throws -> [String: Any] {
         var data: [String: Any] = [
             UserEvent.Field.id.rawValue: eventId,
             UserEvent.Field.otherUserId.rawValue: otherUserId,
             UserEvent.Field.role.rawValue: role.rawValue,
             UserEvent.Field.status.rawValue: e.status.rawValue,
             UserEvent.Field.type.rawValue: e.type ?? "",
             UserEvent.Field.message.rawValue: e.message ?? "",
             UserEvent.Field.otherUserName.rawValue: otherName,
             UserEvent.Field.otherUserPhoto.rawValue: otherPhoto ?? "",
             UserEvent.Field.updatedAt.rawValue: FieldValue.serverTimestamp()
         ]
         
         if let t = e.time { data[UserEvent.Field.time.rawValue] = t }
         if let p = e.location {
             let place = try Firestore.Encoder().encode(p)
             data[UserEvent.Field.place.rawValue] = place
         }
         if let photo = otherPhoto {
             data[UserEvent.Field.otherUserPhoto.rawValue] = photo
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
 
 */
