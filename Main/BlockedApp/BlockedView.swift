//
//  LockedScreen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
// Implement a 'pay' to unlock again. 

import SwiftUI

struct BlockedScreen: View {
    
    let vm: FrozenViewModel
    let email: String    
    
    var body: some View {
        if let blockedContext = vm.user.blockedContext {
            VStack(spacing: 48) {
                VStack(spacing: 10) {
                    Text("Account Blocked")
                        .font(.custom("SFProRounded-Bold", size: 32))
                    
                    Text(verbatim: email)
                        .font(.body(14, .medium))
                        .foregroundStyle(Color.grayText)
                }
                Image("Monkey")
                VStack(spacing: 12) {
                    Text("Account blocked for not showing")
                        .font(.body(17, .italic))
                        .foregroundStyle(Color.grayText)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)

                    BlockedContextView(frozenContext: blockedContext, vm: vm)
                }
            }
            .padding(.top, 96)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
        }
    }
}

//#Preview {
//    LockedScreen()
//}

/*
 //            .overlay (alignment: .topTrailing){
 //                TabInfoButton(showScreen: $showWhyBlocked)
 //            }
 //            .sheet(isPresented: $showWhyBlocked) {
 //                LockedInfo()
 //            }
//     @State var showWhyBlocked: Bool = false
 */
