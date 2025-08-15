//
//  AppState.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.

import SwiftUI

struct RootView : View {
    
    @Environment(\.appDependencies) private var dep
    @State private var session = AppSession(dep: .init())
    
    
    var body: some View {
//        Group {
            switch session.stage {
            case .booting:
                ZStack { Color.accent}.task { await session.start() }
                
            case .needsLogin:
                LoginContainer()
                
            case .ready:
                AppContainer()
            }
//        }
    }
}

#Preview {
    RootView()
}

