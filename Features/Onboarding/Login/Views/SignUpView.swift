//
//  SignUpPage.swift
//  Scoop
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI


struct SignUpView: View {
    
    @Environment(AppDependencies.self) private var dep
    @State var showCover: Bool = false
    @State var tabSelection: Int? = 0
    
    @State var isShowing: Bool = false
    
    var body: some View {
        VStack(spacing: 48){
            
            titleSection
            
            VStack(spacing: 24) {
                tabSection
            }
            VStack(spacing: 8) {
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
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                Image("CoolGuys")
                    .resizable()
                    .scaledToFit()
//                    .frame(width: 250, height: 250)
                    .padding(.horizontal, 72)
                    .containerRelativeFrame([.horizontal, .vertical])
                    .id(0)

                VStack(spacing: 36) {
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
            .scrollTargetLayout()
        }
        .frame(height: 200)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $tabSelection)
        .scrollIndicators(.hidden)
    }
    
    private var titleSection: some View {
        VStack(spacing: 24){
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
                .underline()
                .onTapGesture { print("Paste T & Cs here")}
        }
        .font(.body(10, .medium))
        .padding(.horizontal, 12)
        .foregroundStyle(Color.textSecondary)
    }
}
