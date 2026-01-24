//
//  FrozenHomeViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//

import Foundation

@Observable
class FrozenViewModel {
    
    var sessionManager : SessionManager
    
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
}
