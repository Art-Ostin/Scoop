//
//  BlockedContainer.swift
//  Scoop
//
//  Created by Art Ostin on 25/01/2026.
//File only exists to update views so that it works

import SwiftUI

struct BlockedContainer: View {
    @Environment(\.appDependencies) private var dep
    var body: some View {
        BlockedScreen(vm: FrozenViewModel(sessionManager: dep.sessionManager, cacheManager: dep.cacheManager, authManager: dep.authManager, eventManager: dep.eventManager), email: dep.sessionManager.user.email)
    }
}
