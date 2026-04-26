//
//  LockedScreen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
// Implement a 'pay' to unlock again. 

import SwiftUI

struct BlockedView: View {
    
    let vm: FrozenViewModel
    var email: String {vm.sessionManager.user.email}
    
    @State var showSettings: Bool = false
    @State var showBlockedInfo = false
    
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
                    .onTapGesture {
                        showBlockedInfo = true
                    }
                VStack(spacing: 12) {
                    Text("Account blocked for not showing")
                        .font(.body(17, .italic))
                        .foregroundStyle(Color.grayText)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                    
                    BlockedContextView(frozenContext: blockedContext, vm: vm, isBlock: true)
                        .onTapGesture { showBlockedInfo  = true }
                }
            }
            .padding(.top, 96)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .fullScreenCover(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView(vm: SettingsViewModel(authService: vm.authService, sessionManager: vm.sessionManager))
                }
            }
            .overlay(alignment: .topLeading) {
                HStack {
                    SettingsButton(showSettingsView: $showSettings)
                    Spacer()
                    TabInfoButton(showScreen: $showBlockedInfo)
                }
                .padding(.horizontal)
            }
            .sheet(isPresented: $showBlockedInfo) {
                FrozenExplainedScreen(vm: vm, name: blockedContext.profileName, frozenUntilDate: Date(), isBlocked: true)
            }
        }
    }
}
