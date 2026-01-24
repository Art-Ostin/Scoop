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
    var userManager: UserManager
    var eventManager: EventManager
    var cycleManager: CycleManager
    var sessionManager: SessionManager
    
    init(cacheManager: CacheManaging, userManager: UserManager, eventManager: EventManager, cycleManager: CycleManager, sessionManager: SessionManager) {
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.eventManager = eventManager
        self.cycleManager = cycleManager
        self.sessionManager = sessionManager
    }

    var events: [ProfileModel] { sessionManager.events}
    
    func updateEventStatus(eventId: String, status: EventStatus) async throws {
        try await eventManager.updateStatus(eventId: eventId, to: status)
    }
    
    func loadImages(profileModel: ProfileModel) async -> [UIImage] {
        return await cacheManager.loadProfileImages([profileModel.profile])
    }
    
    func cancelEvent(event: UserEvent) async {
        //Get the fields for the 'blockedContext'
        let profileName = event.otherUserName
        let eventTime = "\(EventFormatting.expandedDate(event.time)) · \(EventFormatting.hourTime(event.time))"
        let eventPlace = event.place.name ?? event.place.address.map { String($0.suffix(10)) }  ?? ""
        let url = URL(string: event.otherUserPhoto)
        let blockedContext = BlockedContext(profileImage: url!, profileName: profileName, eventPlace: eventPlace, eventTime: eventTime, eventMessage: event.message, eventType: event.type)
        let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        
        //Update the user to frozen for two weeks
        try? await userManager.updateUser(userId: sessionManager.user.id, values: [.blockedContext : blockedContext] )
        try? await userManager.updateUser(userId: sessionManager.user.id, values: [.frozenUntil : twoWeeksFromNow] )
        
        //Update the status of the event
        if let id = event.id {
            do {
                try await eventManager.updateStatus(eventId: id, to: .cancelled)
            } catch {
                print(error)
            }
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

