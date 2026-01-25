//
//  BlockedContainer.swift
//  Scoop
//
//  Created by Art Ostin on 25/01/2026.
//

import SwiftUI

struct BlockedContainer: View {
    @Environment(\.appDependencies) private var dep
    var body: some View {
        if dep.sessionManager.events.isEmpty {
            BlockedWithEvents(vm: FrozenViewModel(sessionManager: dep.sessionManager, cacheManager: dep.cacheManager, authManager: dep.authManager, eventManager: dep.eventManager))
        } else {
            FrozenWithEvents(vm: FrozenViewModel(sessionManager: dep.sessionManager, cacheManager: dep.cacheManager, authManager: dep.authManager, eventManager: dep.eventManager))
        }
    }
}

#Preview {
    BlockedContainer()
}
