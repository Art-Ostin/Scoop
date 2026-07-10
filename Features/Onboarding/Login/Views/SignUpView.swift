//
//  SignUpPage.swift
//  Scoop
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI


struct SignUpView: View {
    
    //Injected
    @Environment(AppDependencies.self) private var dep

    //Local view state
    @State private var showCover: Bool = false
    @State private var tabSelection: Int? = 0

    var body: some View {
        VStack(spacing: Spacing.xxl){
            
            titleSection
            
            VStack(spacing: Spacing.lg) {
                tabSection
            }
            VStack(spacing: Spacing.xs) {
                ActionButton(text: "Login / Sign Up", hPadding: 24) { showCover = true}
                termsText
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
        .background(Color.appCanvas)
        .fullScreenCover(isPresented: $showCover) {
            EnterEmailView(vm: VerifyEmailViewModel(session: dep.session, defaultsManager: dep.defaultsManager, authService: dep.authService, userRepo: dep.userRepo))
        }
    }
}

extension SignUpView {
    
    private var tabSection: some View {
        PagerScrollView {
            Image("CoolGuys")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 72)
                .containerRelativeFrame([.horizontal, .vertical])
                .id(0)

            VStack(spacing: Spacing.xl) {
                (Text("Skip small talk: ").bold() + Text("No 'likes'. Match, then send a time & place to meet."))
                (Text("Social Scoop: ").bold() + Text("Meet amongst each other's friends, or a double date!"))
            }
            .font(.body(.regular))
            .lineSpacing(12)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 48)
            .containerRelativeFrame([.horizontal, .vertical])
            .id(1)
        }
        .frame(height: 200)
        .scrollPosition(id: $tabSelection)
    }
    
    private var titleSection: some View {
        VStack(spacing: Spacing.lg){
            Text("Scoop")
                .font(.title())
                .foregroundStyle(Color.textPrimary)
            
            (Text(tabSelection == 0 ? "Made by and for " : "Only available to ")
             + Text("Students"))
              .contentTransition(.opacity)
              .animation(.easeInOut(duration: 0.25), value: tabSelection)
              .font(.body())
        }
    }
    
    private var termsText: some View {
        HStack(spacing: 0) {
            Text("By signing up, you agree to the")
            
            Text(" Terms")
                .underline() // TODO: wire up the Terms & Conditions link
        }
        .font(.body(10, .medium))
        .padding(.horizontal, 12)
        .foregroundStyle(Color.textSecondary)
    }
}
