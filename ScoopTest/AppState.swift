//
//  BootCoordinator.swift
//  ScoopTest
//
//  Created by Art Ostin on 13/08/2025.
//

import SwiftUI


@MainActor @Observable
final class AppState {
    enum Stage: Equatable {
        case boot
        case authRequired
        case onboarding
        case main
        case blocked         
    }

    var stage: Stage = .boot
}
