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
        var data: [String: Any] = [
            "event_id" : event.id,
            "profile1": event.profile,
            "profile2": event.profile2,
            "message" : event.message ?? ""
            ]
        if let type = event.type {
            data["Type"] = type
        }
        if let time = event.time {
            data["Date"] = time
        }
        if let location = event.location {
            data["Place"] = location
        }
        eventDocument(id: event.id).setData(data)
    }
    
}

