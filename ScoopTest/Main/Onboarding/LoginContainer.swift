//
//  LoginContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 20/07/2025.
//

import SwiftUI


struct LoginContainer: View {
    
    @State var showEmail: Bool = true

    
    var body: some View {
        ZStack {
            if showEmail {
                SignUpView(showEmail: $showEmail)
            } else {
                LimitedAccessView()
            }
        }
    }
}

#Preview {
    LoginContainer()
}
