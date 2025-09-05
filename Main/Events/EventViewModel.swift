//
//  EventViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import Foundation
import SwiftUI


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
}
