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
    @State var tabSelection: Int? = 0

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
            .sheet(isPresented: $showInfo) {FrozenInfo(vm: vm, name: frozenContext.profileName, frozenUntilDate: frozenUntilDate, isBlocked: false)}
            .background(Color.appCanvas)
            .fullScreenCover(isPresented: $showSettings) {
                NavigationStack {
                    SettingsContainer(vm: SettingsViewModel(authService: vm.authService, session: vm.session, defaults: vm.defaults))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: tabSelection)
        }
    }
}

extension FrozenView {
    private func frozenHeader(_ date: Date) -> some View {
        VStack(spacing: 12) {
            Text("Account Frozen Until")
                .font(.body(17, .medium))
            
            Text(FormatEvent.dayAndTime(date))
                .font(.title())
        }
    }
    
    private func tabSection(frozenContext: BlockedContext, frozenUntilDate: Date) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                BlockedContextView(frozenContext: frozenContext, vm: vm, isBlock: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .containerRelativeFrame(.horizontal)
                    .onTapGesture {
                        showInfo.toggle()
                    }
                    .id(0)

                VStack(spacing: 48) {
                    LargeClockView(targetTime: frozenUntilDate)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            showInfo.toggle()
                        }

                    Text(verbatim: vm.user.email)
                        .font(.body(14, .medium))
                        .foregroundStyle(Color.grayText)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 24)
                .containerRelativeFrame(.horizontal)
                .id(1)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $tabSelection)
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            PageIndicator(count: 2, selection: tabSelection ?? 0)
                .padding(.bottom, 36)
        }
    }
    
    private var tabTitle: some View {
        Text("Account frozen for" +  (tabSelection == 0 ? " cancelling" : ":"))
            .font(.body(17, .italic))
            .foregroundStyle(Color.grayText)
            .lineSpacing(6)
            .multilineTextAlignment(.center)
            .transition(.opacity)
    }
    
    private var actionBar: some View {
        HStack {
//            SettingsButton { showSettings = true }
            Spacer()
            InfoButton(showScreen: $showInfo, isAtTopOfScroll: true)
        }
        .padding(.horizontal)
    }
}

/*
 //            .frame(width: 245, alignment: .leading)
 //            .frame(maxWidth: .infinity, alignment: .center)
 */
