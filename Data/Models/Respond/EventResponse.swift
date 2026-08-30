//
//  RespondEvent.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI
import MapKit

//Countering an invite with a different plan. The invite being answered is carried whole, so the
//repo can retire it into the event's log without the caller unpacking it field by field.
struct EventResponse {
    let oldEvent: UserEvent
    let userId: String

    let newTimes: ProposedTimes
    let newType: Event.EventType
    let newPlace: EventLocation
    let newMessage: String?

    var eventId: String { oldEvent.id }
    //The retiring proposal was theirs, so they are who the new one goes to
    var otherUserId: String { oldEvent.otherUserId }

    //What actually changed, not which sheet it came from: opening the full editor and only
    //moving the days is a new time, and the invite card should say so
    var kind: ProposalKind {
        newType == oldEvent.type
        && newPlace == oldEvent.location
        && newMessage == oldEvent.message
        ? .newTime : .newEvent
    }

    init(oldEvent: UserEvent, newEvent: EventFieldsDraft, userId: String) {
        self.oldEvent = oldEvent
        self.userId = userId

        newTimes = newEvent.time
        newType = newEvent.type
        newPlace = newEvent.place ?? EventLocation(mapItem: .mcGill)
        newMessage = newEvent.message
    }
}

struct EventFieldsDraft: Codable, Equatable {
    var type: Event.EventType = .socialMeet
    var time: ProposedTimes = .init()
    var place: EventLocation?
    var message: String?
    
    var hasChanges: Bool {
        !time.dates.isEmpty || place != nil || type != .socialMeet || message != nil
    }
    var isComplete: Bool {
        !time.dates.isEmpty && place != nil
    }
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
