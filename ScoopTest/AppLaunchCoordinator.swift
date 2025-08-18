//
//  AppBootstrapper.swift
//  ScoopTest
//
//  Created by Art Ostin on 15/08/2025.
//

import SwiftUI

@MainActor
struct Bootstrapper {
    
    @Binding var appState: AppState
    
    let dep: AppDependencies
    
    func start () async {
        
        do {
            let user = try await dep.userManager.loadUser()
            dep.configure(user: user)

            Task(priority: .utility) {
                await prefetch()
            }
            appState = .app
        } catch {
            appState = .login
        }
    }
    
    
    @MainActor
    func prefetch() async {
        Task {
            do {
                try await dep.sessionManager.loadprofileRecs()
            } catch {
                print("error")
                print(error)
            }
            await dep.sessionManager.loadProfileInvites()
        }
    }
}

