//
//  FlowMode.swift
//  ScoopTest
//
//  Created by Art Ostin on 27/07/2025.
//

import SwiftUI

enum FlowMode {
    case onboarding(step: Int, advance: () -> Void)
    case profile
}

struct FlowModeKey: EnvironmentKey {
    static var defaultValue: FlowMode = .profile
}

extension EnvironmentValues {
    var flowMode: FlowMode {
        get { self[FlowModeKey.self]}
        set { self[FlowModeKey.self] = newValue }
    }
}


