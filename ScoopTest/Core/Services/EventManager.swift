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
    
    @ObservationIgnored private let user: CurrentUserStore
    
    init (user: CurrentUserStore) {
        self.user = user
    }
    
    private let eventCollection = Firestore.firestore().collection("events")
    
    private func eventDocument(id: String) -> DocumentReference {
        eventCollection.document(id)
    }
    
    func createEvent(event: Event) async throws {
        try eventDocument(id: event.id).setData(from: event)
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
    
    func getUserEvents ()  async throws  -> [Event] {
        guard let currentUser = user.user else {return []}
        let userId = currentUser.userId
        let snapshot = try await eventCollection.getDocuments()
        let events = snapshot.documents.compactMap { try? $0.data(as: Event.self) }
        return events
            .filter { $0.profile1_id == userId || $0.profile2_id == userId}
    }
    
    func getUserCurrentEvents () async throws -> [Event] {
        
        let events = try await getUserEvents()
        let now = Date()
        
        let currentEvents = events.filter {$0.time ?? Date() > now}
        let currentAcceptedEvents = currentEvents.filter {$0.status == .accepted ?? false}
        
    }
    
}
