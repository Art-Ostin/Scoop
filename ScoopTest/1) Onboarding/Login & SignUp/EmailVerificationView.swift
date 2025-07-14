//
//  EmailVerificationPage.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/07/2025.
//

import SwiftUI

@Observable class EmailVerificationPageViewModel {
    
    
    // Logic for the "Click Resend" and Confirm button
    
    var email = "arthur.ostin@mail.mcgill.ca"
    
    let countdownDuration = 20
    
    var totalDuration: Int {1 + countdownDuration}
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
    
    
    // Logic for the AnimationTimer
    
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
        
    @State var vm = EmailVerificationPageViewModel()
    
    
    var body: some View {
        VStack(spacing: 24) {
            SignUpTitle(text: "Check your email")
                .padding(.top, 144)
            
            HStack(spacing: 42) {
                Text(verbatim: vm.email)
                    .foregroundStyle(Color.grayText)
                
                vm.resendEmail()
            }
            .font(.body())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 200)
            
            vm.loadingAnimation()
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    EmailVerificationView()
}
