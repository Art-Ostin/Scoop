//
//  EventManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation
import FirebaseFirestore


@Observable
class EventManager {
    
    @ObservationIgnored private let user: UserManager
    @ObservationIgnored private let profile: ProfileManaging
    
    init (user: UserManager, profile: ProfileManaging) {
        self.user = user
        self.profile = profile
    }
    
    private let eventCollection = Firestore.firestore().collection("events")
        
    private func eventDocument(id: String) -> DocumentReference {
        eventCollection.document(id)
    }
    
    func createEvent(event: Event) async throws {
        var event = event
        event.initiatorId = currentId()
        try eventDocument(id: event.id ?? "").setData(from: event)
    }
    
    func fetchEvent(eventId: String) async throws -> Event {
        try await eventDocument(id: eventId).getDocument(as: Event.self)
    }
    
    func updateTime(eventId: String, time: Date) async throws {
        let data: [String: Any] = [
            "time": time
        ]
        try await eventDocument(id: eventId).updateData(data)
    }
    
    func updateEvent(eventId: String, updateTo: Bool) async throws {
        let data: [String: Any] = [
            "accepted": updateTo
        ]
        try await eventDocument(id: eventId).updateData(data)
    }
    
    func getEventMatch(event: Event) async throws -> UserProfile {
        let ids = [event.initiatorId ?? "", event.recipientId ?? ""]
        let matchId = ids.filter ( { $0 != currentId() }).first ?? ""
        return try await profile.getProfile(userId: matchId)
    }
    
    
    
    
    //----------------
    
    private func currentId() -> String {
        guard let uid = user.user?.userId else { return ""}
        return uid
    }
    
    private func involvedFilter(for uid: String) -> Filter {
        .orFilter([
            .whereField(Event.CodingKeys.initiatorId.stringValue, isEqualTo: uid),
            .whereField(Event.CodingKeys.recipientId.stringValue, isEqualTo: uid)
        ])
    }
    
    enum EventScope { case upcomingAccepted, upcomingInvited, pastAccepted }
    
    func eventsQuery (_ scope: EventScope, now: Date = .init()) throws -> Query {
        let uid = currentId()
        let plus3h = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
        switch scope {
        case .upcomingInvited:
            return eventCollection
                .whereField(Event.CodingKeys.recipientId.stringValue, isEqualTo: uid)
                .whereField(Event.CodingKeys.time.stringValue, isGreaterThan: Timestamp(date: plus3h))
                .order(by: Event.CodingKeys.time.stringValue)
        case .upcomingAccepted:
            return eventCollection
                .whereFilter(.andFilter([
                    involvedFilter(for: uid),
                    .whereField(Event.CodingKeys.time.stringValue, isGreaterThan: Timestamp(date:now)),
                    .whereField(Event.CodingKeys.status.stringValue, isEqualTo: Status.accepted.rawValue)
                ]))
                .order(by: Event.CodingKeys.time.stringValue)
        case .pastAccepted:
            return eventCollection
                .whereFilter(.andFilter([
                    involvedFilter(for: uid),
                    .whereField(Event.CodingKeys.time.stringValue, isLessThan: Timestamp(date:plus3h)),
                    .whereField(Event.CodingKeys.status.stringValue, isEqualTo: Status.accepted.rawValue)
                ]))
                .order(by: Event.CodingKeys.time.stringValue)
        }
    }
    
    private func getEvents(_ scope: EventScope, now: Date = .init()) async throws -> [Event] {
        var q = try eventsQuery(scope, now: now)
        return try await q.getDocuments(as: Event.self)
    }
    
    func getUpcomingAcceptedEvents() async throws -> [Event] {
        try await getEvents(.upcomingAccepted)
    }
    func getUpcomingInvitedEvents() async throws -> [Event] {
        try await getEvents(.upcomingInvited)
    }
    func getPastAcceptedEvents(limit: Int? = nil) async throws -> [Event] {
        try await getEvents(.pastAccepted)
    }
    
    
}

extension Query {
    
    func getDocuments<T>(as: T.Type) async throws -> [T] where T: Decodable {
        let snapshot = try await self.getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self)}
    }
    
}
