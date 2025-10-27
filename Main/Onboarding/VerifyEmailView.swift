//
//  EmailVerificationPage.swift
//  ScoopTest
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
                    .foregroundStyle(Color.appGreen)
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
    
    @Environment(\.appState) private var appState
    
    @State var UILogic = VerifyEmailUILogic()
    @Bindable var vm: VerifyEmailViewModel
    
    @FocusState var focused: Bool
    
    @State var code = ""
    
    var body: some View {
        VStack(spacing: 24) {
            SignUpTitle(text: "Check Your email")
            
            HStack(spacing: 48) {
                Text("\(vm.email)")
                    .foregroundStyle(Color.grayText)
                UILogic.resendEmail()
            }
            .font(.body())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 72)
            
            EnterOTP(code: $code)
        }
        .padding(.top, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity,  alignment: .top)
        .padding(.horizontal)
        .background(Color.background)
        .flowNavigation()
        .task {
            try? await Task.sleep(nanoseconds: UInt64(2 * 1_000_000))
            do {
                try await vm.signInUser(email: vm.email, password: vm.password)
            } catch {
                guard let _ = try? await vm.createAuthUser(email: vm.email, password: vm.password) else {return}
            }
        }
    }
}
