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
        }
        .onAppear {
            let authUser = try? AuthenticationManager.instance.getAuthenticatedUser()
            showLogin = authUser == nil
        }
    }
}

#Preview {
    RootView()
}
