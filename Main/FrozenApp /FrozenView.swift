//
//  Frozen Screen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct FrozenView: View {
    
    let vm: FrozenViewModel
    
    @State var showInfo: Bool = false
    @State var showSettings : Bool = false
    @State var tabSelection: Int = 0
    
    var body: some View {
        if let frozenContext = vm.user.blockedContext, let frozenUntilDate = vm.user.frozenUntil {
            VStack(spacing: 72) {
                
                frozenHeader(frozenUntilDate)
                
                Image("Monkey")
                
                VStack(spacing: 12) {
                    tabTitle
                    tabSection(frozenContext: frozenContext, frozenUntilDate: frozenUntilDate)
                }
            }
            .padding(.top, 72)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay (alignment: .top) {actionBar}
            .sheet(isPresented: $showInfo) {FrozenExplainedScreen(vm: vm)}
            .background(Color.background)
            .fullScreenCover(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView(vm: SettingsViewModel(authManager: vm.authManager, sessionManager: vm.sessionManager))
                }
            }
        }
    }
}

extension FrozenView {
    private func frozenHeader(_ date: Date) -> some View {
        VStack(spacing: 12) {
            Text("Account Frozen Until")
                .font(.body(17, .medium))
            
            Text(EventFormatting.expandedDate(date))
                .font(.custom("SFProRounded-Bold", size: 32))
        }
    }
    
    private func tabSection(frozenContext: BlockedContext, frozenUntilDate: Date) -> some View {
        TabView(selection: $tabSelection) {
            BlockedContextView(frozenContext: frozenContext, vm: vm)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .tag(0)
            
            VStack(spacing: 48) {
                LargeClockView(targetTime: frozenUntilDate) {}
                    .frame(maxWidth: .infinity)
                
                Text(verbatim: vm.user.email)
                    .font(.body(14, .medium))
                    .foregroundStyle(Color.grayText)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 24)
            .tag(1)
            
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .bottom) {
            PageIndicator(count: 2, selection: tabSelection)
                .padding(.bottom, 36)
        }
    }
    
    private var tabTitle: some View {
        Text("Account Frozen " +  (tabSelection == 0 ? "for Cancelling" : "until:"))
            .font(.body(17, .italic))
            .foregroundStyle(Color.grayText)
            .lineSpacing(6)
            .multilineTextAlignment(.center)
            .transition(.opacity)
    }
    
    private var actionBar: some View {
        HStack {
            SettingsButton(showSettingsView: $showSettings)
            Spacer()
            TabInfoButton(showScreen: $showInfo)
        }
        .padding(.horizontal)
    }
}
