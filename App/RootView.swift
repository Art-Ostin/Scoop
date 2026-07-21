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

    //Injected
    @Environment(AppDependencies.self) private var dep

    //Local view state
    @State private var showSignUpSheet = false

    var body: some View {
        Group {
            switch dep.session.appState {
            case .booting: BootingScreen()
            case .login: SignUpView(showSignUpSheet: $showSignUpSheet)
            case .createAccount: OnboardingHomeView()
            case .app: AppContainer(dependencies: dep)
            case .frozen: FrozenContainer()
            }
        }
        .sheet(isPresented: $showSignUpSheet) {
            EnterEmailView(vm: VerifyEmailViewModel(session: dep.session, defaultsManager: dep.defaultsManager, authService: dep.authService, userRepo: dep.userRepo))
                .presentationBackground(Color(red: 1, green: 1, blue: 0.98))
        }
        .onChange(of: dep.session.appState) { _, newState in
            if newState != .login { showSignUpSheet = false }
        }
    }
}
