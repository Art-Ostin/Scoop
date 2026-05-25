//
//  AppsRouter.swift
//  Scoop Test
//
//  Created by Art Ostin on 25/05/2026.
//

import SwiftUI

@Observable
class AppRouter {
    
    var selectedTab: Tab = .meet
    
}

enum Tab: Hashable {
    case meet, invites, events, pastEvents
}
