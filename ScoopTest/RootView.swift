//
//  AppState.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.

import SwiftUI

struct RootView : View {
    
    @Environment(\.appDependencies) private var dep
    @State var showLogin: Bool = false
    
    var body: some View {
        
        ZStack {
            if !showLogin {
                AppContainer(showLogin: $showLogin)

            } else {
                LoginContainer(showLogin: $showLogin)
                    .transition(.move(edge: .bottom))
            }
        }.task {
            do {
                _ = try dep.authManager.getAuthenticatedUser()
                try await dep.userManager.loadUser()
                showLogin = false
            } catch  {
                showLogin = true
            }
        }
    }
}

#Preview {
    RootView()
}

