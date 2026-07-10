//
//  EmailVerificationPage.swift
//  Scoop
//
//  Created by Art Ostin on 05/07/2025.
//

import SwiftUI
import FirebaseAuth

@Observable class VerifyEmailUILogic {
    
    // Logic for the "Click Resend" and Confirm button
    let countdownDuration = 20
    var totalDuration: Int {2 + countdownDuration}
    var timeRemaining = 0
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    func resendEmail() -> some View {
        Group {
            if timeRemaining == 0 {
                Text("Resend")
                    .font(.body(12, .bold))
                    .foregroundStyle(Color.accent)
                    .onTapGesture {
                        withAnimation { self.timeRemaining = self.totalDuration }
                    }
            }
            else if timeRemaining > countdownDuration {
                Image(systemName: "checkmark")
                    .font(.body(12, .bold))
                    .foregroundStyle(Color.successGreen)
            }
            else {
                Text("\(timeRemaining)")
            }
        }
        .onReceive(timer) { [self] _ in
            if self.timeRemaining > 0 {
                if timeRemaining == countdownDuration + 1 {
                    withAnimation {timeRemaining -= 1}
                } else {
                    timeRemaining -= 1
                }
            }
        }
    }
    
    // Logic for the Animation
    let animationTimer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    
    var count = 0
    
    func loadingAnimation() -> some View {
        HStack {
            Circle()
                .offset(y: count == 0 ? 20 : 0)
            Circle()
                .offset(y: count == 1 ? 20 : 0)
            Circle()
                .offset(y: count == 2 ? 20 : 0)
        }
        .frame(width: 35, height: 35)
        .onReceive(animationTimer) { [self]_ in withAnimation {count = count < 7 ? count + 1 : 0}}
    }
}


struct VerifyEmailView: View {
    
    //Injected
    @Bindable var vm: VerifyEmailViewModel

    //Local view state
    @State private var uiLogic = VerifyEmailUILogic()
    @State private var code = ""
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            SignUpTitle(text: "Check Your email")
            
            HStack(spacing: Spacing.xxl) {
                Text("\(vm.email)")
                    .foregroundStyle(Color.textSecondary)
                uiLogic.resendEmail()
            }
            .font(.body())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, Spacing.titleGap)
            
            EnterOTP(code: $code)
        }
        .padding(.top, Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity,  alignment: .top)
        .padding(.horizontal)
        .background(Color.appCanvas)
        .flowNavigation()
        .onChange(of: code) {
            if code.count == 6 {
                Task {
                    do {
                        try await vm.signInUser(email: vm.email, password: vm.password)
                    } catch {
                        guard let _ = try? await vm.createAuthUser(email: vm.email, password: vm.password) else {return}
                    }
                }
            }
        }
    }
}
