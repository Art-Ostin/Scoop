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

    @Environment(\.stateOfApp) private var state
    
    var body: some View {
        
        Group {
            switch state.wrappedValue {
                
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
