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
}

@Observable
final class EventUIState {
    var showEventDetails: UserEvent? = nil
    var showMessageScreen: ProfileModel? = nil
    var showCantMakeIt: ProfileModel? = nil
    var selectedProfile: ProfileModel? = nil
}
