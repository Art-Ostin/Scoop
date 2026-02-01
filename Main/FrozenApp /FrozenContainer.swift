//
//  SuspendedAccountContainer.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//File only used to inject depenedencies to keep dependency injection consistent and not have dependencies at AppContainer level

import SwiftUI

struct FrozenContainer: View {
    @Environment(\.appDependencies) private var dep
    private var vm: FrozenViewModel {
        FrozenViewModel(sessionManager: dep.sessionManager, authService: dep.authService, userRepo: dep.userRepo, eventRepo: dep.eventRepo,imageLoader: dep.imageLoader)
    }
    var body: some View {
        if dep.sessionManager.user.isBlocked {
            BlockedView(vm: vm)
        } else if dep.sessionManager.events.isEmpty {
            FrozenView(vm: vm)
        } else {
            FrozenWithEvents(vm: vm)
        }
    }
}
