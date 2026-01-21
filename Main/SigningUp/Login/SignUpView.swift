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
    @State var tabSelection: Int = 0
    
    @State var isShowing: Bool = false
    
    var body: some View {
        VStack(spacing: 48){
            
            titleSection
            
            VStack(spacing: 24) {
                tabSection
                PageIndicator(count: 2, selection: tabSelection)
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
    
    private var tabSection: some View {
        TabView(selection: $tabSelection) {
            Image("CoolGuys")
                .resizable().scaledToFit()
                .tag(0)
            
            VStack(spacing: 36) {
                (Text("Skip small talk: ").bold() + Text("No 'likes'. Match, then send a time & place to meet."))
                (Text("Social Scoop: ").bold() + Text("Meet amongst each other's friends, or a double date!"))
            }
            .font(.body(.regular))
            .lineSpacing(12)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 48)
            .tag(1)
        }
        .frame(height: 200)
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
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
