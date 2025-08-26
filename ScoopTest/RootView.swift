//
//  AppState.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.

import SwiftUI

enum AppState {
    case booting, login, createAccount, app
}

struct RootView : View {

    @Environment(\.appState) private var state
    @Environment(\.appDependencies) private var dep
    
    var body: some View {
        
        Group {
            switch state.wrappedValue {
                
            case .booting:
                ZStack { Color.accent.ignoresSafeArea()}
                
            case .login:
                SignUpView()
                
            case .createAccount:
                LimitedAccessView()
                
            case .app:
                AppContainer()
                    .id(dep.sessionManager.session?.user.id ?? "signed-out")
            }
        }
    }
}
