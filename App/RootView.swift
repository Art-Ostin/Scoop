//
//  AppState.swift
//  Scoop
//
//  Created by Art Ostin on 18/06/2025.

import SwiftUI

enum AppState {
    case booting, login, createAccount, app, frozen
}

struct RootView : View {

    @Environment(AppDependencies.self) private var dep

    var body: some View {
        Group {
            switch dep.session.appState {
            case .booting: BootingScreen()
            case .login: SignUpView()
            case .createAccount: OnboardingHomeView()
            case .app: AppContainer(dependencies: dep)
            case .frozen: FrozenContainer()
            }
        }
    }
}
