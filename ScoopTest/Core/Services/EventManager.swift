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
    
    
    func createEvent(event: Event) {
        let data: [String: Any] = ["Event": event]
        eventDocument(id: event.id).setData(data)
    }
    
}

