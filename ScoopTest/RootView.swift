//
//  AppState.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.

import SwiftUI

struct RootView : View {
    
    @State var showLogin: Bool = false
    
    @State private var dependencies = AppDependencies()
    
    var body: some View {
        
        ZStack {
            if !showLogin {
                AppContainer(showLogin: $showLogin)
                    .appDependencies(dependencies)
            } else  {
                LoginContainer(showLogin: $showLogin)
                    .appDependencies(dependencies)
                    .transition(.move(edge: .bottom))
            }
        }.task {
            if let _ = try? dependencies.authManager.getAuthenticatedUser(){
                try? await dependencies.userManager.loadUser()
                _ = try? await dependencies.defaultsManager.retrieveTwoDailyProfiles()
                showLogin = false
            } else {
                showLogin = true
            }
        }
    }
}

#Preview {
    RootView()
}
