//
//  SuspendedAccountContainer.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//File only used to inject depenedencies to keep dependency injection consistent and not have dependencies at AppContainer level

import SwiftUI

struct FrozenContainer: View {
    @Environment(AppDependencies.self) private var dep
    private var vm: FrozenViewModel {
        FrozenViewModel(session: dep.session, defaults: dep.defaultsManager, authService: dep.authService, userRepo: dep.userRepo, chatRepo: dep.chatRepo, eventRepo: dep.eventRepo,imageLoader: dep.imageLoader)
    }
    var body: some View {
        if dep.session.user.isBlocked {
            BlockedView(vm: vm)
        } else if dep.session.events.isEmpty {
            FrozenView(vm: vm)
        } else {
            FrozenWithEvents(vm: vm)
        }
    }
}
