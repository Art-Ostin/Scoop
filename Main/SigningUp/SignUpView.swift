//
//  SignUpPage.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI


struct SignUpView: View {
    
    @Environment(\.appDependencies) private var dep
    @State var showCover: Bool = false
    @State var tabSelection: Int? = 0
    
    var body: some View {
        VStack(spacing: 60){
            titleSection
            SignUpTabView(tabSelection: $tabSelection)
                .overlay(alignment: .bottom) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(tabSelection == 0 ? .black : .grayPlaceholder)
                            .frame(width: 5, height: 5)

                        Circle()
                            .fill(tabSelection == 1 ? .black : .grayPlaceholder)
                            .frame(width: 5, height: 5)
                    }
                        .offset(y: 32)
                }
            VStack(spacing: 8) {
                ActionButton(text: "Login / Sign Up") { showCover = true}
                termsText
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
        .background(Color.background)
        .fullScreenCover(isPresented: $showCover) {
            EnterEmailView(vm: VerifyEmailViewModel(sessionManager: dep.sessionManager, authManager: dep.authManager, userManager: dep.userManager, defaultsManager: dep.defaultsManager))
        }
    }
}

extension SignUpView {
    
    private var titleSection: some View {
        VStack(spacing: 24){
            Text("Scoop")
                .font(.title())
                .foregroundStyle(.black)
            
            (Text(tabSelection == 0 ? "Made by and for " : "Only available to ")
             + Text("McGill students"))
              .contentTransition(.opacity)
              .animation(.easeInOut(duration: 0.25), value: tabSelection)
              .font(.body())
        }
    }
    
    private var termsText: some View {
        HStack(spacing: 0) {
            Text("By signing up, you agree to the")
            
            Text(" Terms")
                .underline()
                .onTapGesture { print("Paste T & Cs here")}
        }
        .font(.body(10, .medium))
        .padding(.horizontal, 12)
        .foregroundStyle(Color.grayText)
    }
}

