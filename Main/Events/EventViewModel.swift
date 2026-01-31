//
//  EventViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import Foundation
import SwiftUI
import MapKit


@MainActor
@Observable class EventViewModel {
    
    var cacheManager: CacheManaging
    var eventManager: EventManager
    var sessionManager: SessionManager
    
    init(cacheManager: CacheManaging, eventManager: EventManager, sessionManager: SessionManager) {
        self.cacheManager = cacheManager
        self.eventManager = eventManager
        self.sessionManager = sessionManager
    }

    var events: [ProfileModel] { sessionManager.events}
    
    func updateEventStatus(eventId: String, status: EventStatus) async throws {
        try await eventManager.updateStatus(eventId: eventId, to: status)
    }
    
    func loadImages(profileModel: ProfileModel) async -> [UIImage] {
        return await cacheManager.loadProfileImages([profileModel.profile])
    }
    
    func cancelEvent(event: UserEvent) async throws {
        //Get the fields for the 'blockedContext'
        guard let acceptedTime = event.acceptedTime else { return }
        let profileName = event.otherUserName
        let eventTime = "\(EventFormatting.expandedDate(acceptedTime)) · \(EventFormatting.hourTime(acceptedTime))"
        let eventPlace = event.place.name ?? event.place.address.map { String($0.suffix(10)) }  ?? ""
        let blockedContext = BlockedContext(profileImage: event.otherUserPhoto, profileName: profileName, eventPlace: eventPlace, eventTime: eventTime, eventMessage: event.message, eventType: event.type)
        let userId = sessionManager.user.id
        
        //Cancell the event which deals with logic of updating user profile etc.
        if let eventId = event.id {
            try await eventManager.cancelEvent(eventId: eventId, cancelledById: userId, blockedContext: blockedContext)
        } else {
            print("No Id found for event!")
        }
    }
}

@Observable
final class EventUIState {
    var showEventDetails: UserEvent? = nil
    var showMessageScreen: ProfileModel? = nil
    var showCantMakeIt: ProfileModel? = nil
    var selectedProfile: ProfileModel? = nil
}

