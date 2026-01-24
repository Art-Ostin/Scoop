//
//  SuspendedAccountContainer.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//File only used to inject depenedencies to keep dependency injection consistent and not have dependencies at AppContainer level

import SwiftUI

struct FrozenContainer: View {
    @Environment(\.appDependencies) private var dep

    var body: some View {
        FrozenView(vm: FrozenViewModel(sessionManager: dep.sessionManager, cacheManager: dep.cacheManager, authManager: dep.authManager))
    }
}
