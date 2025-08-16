//
//  AppState.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.

import SwiftUI

enum AppState {
    case booting, login, app
}

struct RootView : View {

    @Binding var state: AppState
    
    var body: some View {
        
        Group {
            switch state {
                
            case .booting:
                ZStack { Color.accent.ignoresSafeArea()}
                
            case .login:
                LoginContainer()
                
            case .app:
                AppContainer()
            }
        }
    }
}
