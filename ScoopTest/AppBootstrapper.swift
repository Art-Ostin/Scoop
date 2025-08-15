//
//  AppBootstrapper.swift
//  ScoopTest
//
//  Created by Art Ostin on 15/08/2025.
//

import SwiftUI

struct AppBootstrapper {
    
    enum Result {
        case needsLogin
        case ready
    }
    
    func run(_ dep: AppDependencies) async -> Result {
        do {
            _ = try dep.authManager.getAuthenticatedUser()
            return .ready
        } catch {
            return .needsLogin
        }
    }
}

@Observable
final class AppSession {
    
    enum Stage { case booting, needsLogin, ready }
    
    private let dep: AppDependencies
    
    private let bootstrapper: AppBootstrapper
    
    var stage: Stage = .booting

    init(dep: AppDependencies, bootstrapper: AppBootstrapper = .init()) {
        self.dep = dep
        self.bootstrapper = bootstrapper
    }
    
    
    func start() async {
        switch await bootstrapper.run(dep) {
        case .ready:      await MainActor.run { stage = .ready }
        case .needsLogin: await MainActor.run { stage = .needsLogin }
        }
    }
}
