//
//  EmailVerificationPage.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/07/2025.
//

import SwiftUI
import FirebaseAuth

@Observable class EmailVerificationUILogic {
    
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
                    .foregroundStyle(Color.defualtGreen)
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


struct EmailVerificationView: View {
    
    @Environment(\.appDependencies) private var dependencies
    @State var UILogic = EmailVerificationUILogic()
    @Binding var vm: EmailVerificationViewModel
    @Binding var showLogin: Bool
    @Binding var showEmail: Bool
    @FocusState var focused: Bool
    @ObservedObject var otpManager: OTPManager
    
    @State var code = ""
    
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
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
                .padding(.horizontal)
                
                EnterOTP(code: $code)
                if let expected = otpManager.otp {
                  Text("Expected OTP: \(expected)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                } else {
                  Text("No OTP fetched yet")
                    .font(.caption2)
                    .foregroundColor(.orange)
                }
            }
            .padding(.top, 48)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal)
            .flowNavigation()
            Button("Verify Code") {
                Task {
                    do {
                        // this will throw if wrong
                        try await AuthenticateEmail()
                        
                        // now your login/createUser flow
                        if let _ = try? await vm.signInUser(email: vm.email, password: vm.password) {
                            try await dependencies.userStore.loadUser()
                            showLogin = false
                        }
                        else if let _ = try? await vm.createUser(email: vm.email, password: vm.password) {
                            try await dependencies.userStore.loadUser()
                            showEmail = false
                        }
                    }
                }
            }
            .disabled(code.count != 6) // only enable once 6 digits entered
        }
        .padding()
    }
    
    
    private func AuthenticateEmail() async throws -> Bool {
        
        // All Authentication Goes here. The code the user types in is the variable "code". Thus, make this function return true, if the "code" the user types in is equivalent to the code set to the user's email (else return false). (Currently, the function just returns true if the user types in 6 digits).
        
        
        if otpManager.verify(input: code) {
            print("Correct")
            return true
        } else {
            throw NSError(domain: "OTP", code: 0, userInfo: [NSLocalizedDescriptionKey: "Incorrect code"])
        }
    }
}



//#Preview {
//    EmailVerificationView(vm: .constant(EmailVerificationViewModel()), showLogin: .constant(true), showEmail: .constant(true))
//}
