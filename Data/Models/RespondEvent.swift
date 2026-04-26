//
//  RespondEvent.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI
import MapKit

struct EventResponse {
    let eventId: String
    let otherUserId: String
    let userId: String
    
    let oldTimes: ProposedTimes
    let newTimes: ProposedTimes
    
    let oldType: Event.EventType
    let newType: Event.EventType
    
    let oldPlace: EventLocation
    let newPlace: EventLocation
    
    let newMessage: String?
    
    init(oldEvent: UserEvent, newEvent: EventFieldsDraft, userId: String) {
        self.eventId = oldEvent.id
        self.otherUserId = oldEvent.otherUserId
        self.userId = userId
        
        self.oldTimes = oldEvent.proposedTimes
        self.newTimes = newEvent.time
        
        
        self.oldType = oldEvent.type
        self.newType = newEvent.type
        
        self.oldPlace = oldEvent.location
        self.newPlace = newEvent.place ?? EventLocation(mapItem: .mcGill)
         
        self.newMessage = newEvent.message
    }
}

struct EventFieldsDraft: Codable {
    var type: Event.EventType = .drink
    var time: ProposedTimes = .init()
    var place: EventLocation?

    var message: String?
}

//To Use McGill as backup location
extension MKMapItem {
    static var mcGill: MKMapItem {
        let coordinate = CLLocationCoordinate2D(
            latitude: 45.5048,
            longitude: -73.5772
        )

        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = "McGill University"

        return item
    }
}
