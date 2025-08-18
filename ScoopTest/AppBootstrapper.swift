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
            _ = try dep.authManager.getAuthenticatedUser()
            appState = .app
        } catch {
            appState = .login
        }
    }
    
    
    @MainActor
    func prefetch() async {
        print("Step 1: Prefeched called")
        
        Task {
            do{
                print("loaded profiles epon launch")
                try await dep.sessionManager.loadprofileRecs()
            } catch {
                print("error loading profile recs")
                print(error)
            }
        }
        
        Task {await dep.sessionManager.loadProfileInvites()}
        Task {try? await dep.userManager.loadUser()}
    }
}

