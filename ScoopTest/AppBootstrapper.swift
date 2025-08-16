//
//  AppBootstrapper.swift
//  ScoopTest
//
//  Created by Art Ostin on 15/08/2025.
//

import SwiftUI

struct Bootstrapper {
    
    let dep: AppDependencies
    
    func start () async -> AppState {
        do {
            _ = try dep.authManager.getAuthenticatedUser()
            print("User is auth")
            return .app
        } catch {
            print("User is not auth")
            return .login
        }
    }
}
