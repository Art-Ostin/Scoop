//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

struct MeetView: View {
    
    @State var vm: MeetViewModel
    @State var selectedProfile: ProfileModel?
    @State var endTime: Date?
    
    init(vm: MeetViewModel) { _vm = State(initialValue: vm) }
    
    var body: some View {
        ZStack {
            VStack(spacing: 36) {
                Text("Meet")
                    .font(.body(32, .bold))
  
                
                
                
                tabView

                clockView

            }
            .padding(.top, 36)
            
            if let profileModel = selectedProfile {
                profileRecView(profileModel: profileModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

extension MeetView {
    
    private var tabView: some View {
        TabView {
            
            ForEach(vm.invites) { profileInvite in
                ProfileCard(vm: vm, profile: profileInvite, selectedProfile: $selectedProfile)
            }
            
            if vm.showProfilesState != .closed {
                ForEach(vm.profiles) { profileInvite in
                    VStack {
                        Text(profileInvite.profile.name)
                        ProfileCard(vm: vm, profile: profileInvite, selectedProfile: $selectedProfile)
                    }
                }
            } else {
                IntroView(vm: vm)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    private func profileRecView(profileModel: ProfileModel) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { }
            
            ProfileView(vm: ProfileViewModel(profileModel: profileModel, cacheManager: vm.cacheManager, cycleManager: vm.cycleManager, eventManager: vm.eventManager, sesionManager: vm.s)) { withAnimation(.easeInOut(duration: 0.2)) { selectedProfile = nil } }
        }
        .transition(.asymmetric(insertion: .identity, removal: .move(edge: .bottom)))
        .zIndex(1)
    }
    @ViewBuilder private var clockView: some View {
        if let time = vm.endTime, vm.showProfilesState == .active {
            SimpleClockView(targetTime: time) {}
        } else if vm.showProfilesState == .respond {
            Text("Respond to Refresh")
        }
    }
}
