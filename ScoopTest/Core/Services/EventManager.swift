//
//  EventManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation
import FirebaseFirestore



class EventManager {

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
}
