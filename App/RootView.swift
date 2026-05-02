//
//  AppState.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.

import SwiftUI

enum AppState {
    case booting, login, createAccount, app, frozen
}

struct RootView : View {

    @Environment(\.appDependencies) private var dep

    var body: some View {
        Group {
            switch dep.sessionManager.appState {
            case .booting: BootingScreen()
            case .login: SignUpView()
            case .createAccount: OnboardingHomeView()
            case .app: AppContainer()
            case .frozen: FrozenContainer()
            }
        }
    }
}

