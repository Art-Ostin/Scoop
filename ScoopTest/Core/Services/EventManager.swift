//
//  EventManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI



@Observable
class EventManager {
    
    @ObservationIgnored private let user: UserManager
    @ObservationIgnored private let profile: ProfileManaging
    
    init (user: UserManager, profile: ProfileManaging) {
        self.user = user
        self.profile = profile
    }
    
    private let eventCollection = Firestore.firestore().collection("events")
    private let userCollection = Firestore.firestore().collection("users")
    
    
    
    private func eventDocument(id: String) -> DocumentReference {
        eventCollection.document(id)
    }
    private func userEventDocument (userId: String, userEventId: String) -> DocumentReference {
        userEventCollection(userId: userId).document(userEventId)
    }
    
    private func fetchEvent(eventId: String) async throws -> Event {
        try await eventDocument(id: eventId).getDocument(as: Event.self)
    }
    
    
    private var currentId: String? {
        user.user?.userId
    }
    
    
    func eventFormatter (event: UserEvent, isInvite: Bool = true, size: CGFloat = 22) -> some View {
        
        var isMessage: Bool { event.message?.isEmpty == false }
        
        let time = formatTime(date: event.time)
        let type = event.type ?? ""
        let place = event.place?.name  ?? ""
        
        let header =  Text("\(time), \(type), ") + Text(place).foregroundStyle(isInvite ? Color.appGreen : Color.accent).font(.body(size, .bold))
        
        return VStack(alignment: isMessage ? .leading: .center, spacing: isMessage ? 16 : 0) {
            
            header
                .font(.body(size))
                .multilineTextAlignment(isMessage ? .leading : .center)
                .lineSpacing(isMessage ? 4 : 12)
            
            
            if let message = event.message {
                Text (message)
                    .font(.body(.italic))
                    .foregroundStyle(Color.grayText)
            }
        }
    }
    
    func formatTime(date: Date?) -> String {
        guard let date = date else { return "" }
        let dayOfMonth = date.formatted(.dateTime.month(.abbreviated).day(.defaultDigits))
        let weekDay = date.formatted(.dateTime.weekday(.wide))
        let time = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
        
        return "\(weekDay) (\(dayOfMonth)) \(time)"
    }
    
    
    func createEvent(event: Event) async throws {
        //Creates event and local reference in the two users subcollection of events
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let eventRef = db.collection("events").document()
        let eventId = eventRef.documentID
        
        
        guard let initiatorId = currentId,
              let recipientId = event.recipientId else {
            print("failed to get user")
            throw URLError(.userAuthenticationRequired)
        }
        
        var e = event
        e.id = eventId
        e.initiatorId = initiatorId
        
        let recipientProfile = try await profile.getProfile(userId: recipientId)
        let recipientName = recipientProfile.name ?? ""
        let recipientImageString = recipientProfile.imagePathURL?.first ?? ""
        
        let inviterProfile = user.user
        let inviterName = inviterProfile?.name ?? ""
        let inviterImageString = inviterProfile?.imagePathURL?.first ?? ""
        
        
        var eventData: [String: Any] = [
            Event.CodingKeys.id.stringValue: eventId,
            Event.CodingKeys.initiatorId.stringValue: initiatorId,
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
        
        let initiatorEdgeRef = db.collection("users").document(initiatorId)
            .collection("user_events").document(eventId)
        let recipientEdgeRef = db.collection("users").document(recipientId)
            .collection("user_events").document(eventId)
        
        
        let edgeA = try edgeData(otherUserId: recipientId, role: .sent, otherName: recipientName, otherPhoto: recipientImageString)
        let edgeB = try edgeData(otherUserId: initiatorId, role: .received, otherName: inviterName, otherPhoto: inviterImageString)
        
        batch.setData(eventData, forDocument: eventRef)
        batch.setData(edgeA, forDocument: initiatorEdgeRef)
        batch.setData(edgeB, forDocument: recipientEdgeRef)
        
        try await batch.commit()
    }
    
    private func eventsQuery(_ scope: EventScope, now: Date = .init()) throws -> Query {
        
        guard let uid = currentId else { throw URLError(.userAuthenticationRequired) }
        
        
        let plus3h = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
        switch scope {
        case .upcomingInvited:
            return userEventCollection(userId: uid)
                .whereField(UserEvent.CodingKeys.time.stringValue, isGreaterThan: Timestamp(date: Date()))
                .whereField(UserEvent.CodingKeys.role.rawValue, isEqualTo: EdgeRole.received.rawValue)
                .whereField(UserEvent.CodingKeys.status.rawValue, isEqualTo: EventStatus.pending.rawValue)
                .order(by: Event.CodingKeys.time.stringValue)
        case .upcomingAccepted:
            return userEventCollection(userId: uid)
                .whereField(UserEvent.CodingKeys.time.stringValue, isGreaterThan: Timestamp(date: plus3h))
                .whereField(UserEvent.CodingKeys.status.rawValue, isEqualTo: EventStatus.accepted.rawValue)
                .order(by: Event.CodingKeys.time.stringValue)
            
        case .pastAccepted:
            return userEventCollection(userId: uid)
                .whereField(UserEvent.CodingKeys.status.stringValue, isEqualTo: EventStatus.accepted.rawValue)
                .whereField(UserEvent.CodingKeys.time.stringValue, isLessThan: Timestamp(date: plus3h))
        }
    }
    private func getEvents(_ scope: EventScope, now: Date = .init()) async throws -> [UserEvent] {
        let query = try eventsQuery(scope, now: now)
        return try await query
            .getDocuments(as: UserEvent.self)
    }
    
    func getUpcomingAcceptedEvents() async throws -> [UserEvent] {
        try await getEvents(.upcomingAccepted)
    }
    func getUpcomingInvitedEvents() async throws -> [UserEvent] {
        try await getEvents(.upcomingInvited)
    }
    func getPastAcceptedEvents() async throws -> [UserEvent] {
        try await getEvents(.pastAccepted)
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
    
    private func userEventCollection (userId: String) -> CollectionReference {
        userCollection.document(userId).collection("user_events")
    }
}

extension Query {
    func getDocuments<T>(as: T.Type) async throws -> [T] where T: Decodable {
        let snapshot = try await self.getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self)}
    }
}



/* Don't think I need anymore
 func removeUserEvent(userId: String, userEventId: String) async throws {
     try await userEventDocument(userId: userId, userEventId: userEventId).delete()
 }

 func getAllUserEvents(userId: String) async throws -> [UserEvent] {
     try await userEventCollection(userId: userId).getDocuments(as: UserEvent.self)
 }
 */


