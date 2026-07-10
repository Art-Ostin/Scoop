//
//  LockedScreen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
// Implement a 'pay' to unlock again. 

import SwiftUI

struct BlockedView: View {
    
    //Injected
    let vm: FrozenViewModel

    //Local view state
    @State private var showSettings: Bool = false
    @State private var showBlockedInfo = false

    private var email: String { vm.session.user.email }

    var body: some View {
        if let blockedContext = vm.user.blockedContext {
            VStack(spacing: 48) {
                VStack(spacing: 10) {
                    Text("Account Blocked")
                        .font(.title())
                    
                    Text(verbatim: email)
                        .font(.body(14, .medium))
                        .foregroundStyle(Color.textSecondary)
                }
                Image("Monkey")
                    .onTapGesture {
                        showBlockedInfo = true
                    }
                VStack(spacing: 12) {
                    Text("Account blocked for not showing")
                        .font(.body(17, .italic))
                        .foregroundStyle(Color.textSecondary)
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
                    SettingsContainer(vm: SettingsViewModel(authService: vm.authService, session: vm.session, defaults: vm.defaults))
                }
            }
            .overlay(alignment: .topLeading) {
                HStack {
                    Spacer()
                    InfoButton(showScreen: $showBlockedInfo)
                }
                .padding(.horizontal)
            }
            .sheet(isPresented: $showBlockedInfo) {
                FrozenInfo(vm: vm, name: blockedContext.profileName, frozenUntilDate: Date(), isBlocked: true)
            }
        }
    }
}
