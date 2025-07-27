//
//  LoginContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 20/07/2025.
//

import SwiftUI


struct LoginContainer: View {
    
    @State var showEmail: Bool = true
    @Binding var showLogin: Bool
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    var body: some View {
        ZStack {
            if showEmail {
                SignUpView(showEmail: $showEmail, showLogin: $showLogin)
            } else {
                LimitedAccessView(showLogin: $showLogin, auth: dependencies.authManager)
            }
        }
    }
}

#Preview {
    LoginContainer(showLogin: .constant(true))
}
