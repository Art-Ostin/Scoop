//
//  AppState.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.

import SwiftUI

struct RootView : View {
    
    @State var showLogin: Bool = false
    
    var body: some View {
        
        ZStack {
            if !showLogin {
                AppContainer(showLogin: $showLogin)
            } else  {
                LoginContainer(showLogin: $showLogin)
                    .transition(.move(edge: .bottom))
            }
        }.task {
            if let _ = try? AuthenticationManager.instance.getAuthenticatedUser(){
                try? await EditProfileViewModel.instance.loadUser()
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
