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
            
            
            let authUser = try dep.authManager.getAuthenticatedUser()
             
            try await dep.userManager.loadUser(for: authUser)
            
            appState = .app
            
            Task(priority: .utility) {
                await prefetch()
            }
            
        } catch {
            appState = .login
        }
    }
    
    
    @MainActor
    func prefetch() async {
        Task {
            
            try? await dep.userManager.loadUser()
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

