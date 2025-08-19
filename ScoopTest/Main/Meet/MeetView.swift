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
    
    init(vm: MeetViewModel) { _vm = State(initialValue: vm) }
    
    var body: some View {
        ZStack {
            VStack(spacing: 36) {
                Text("Meet")
                    .font(.body(32, .bold))
                tabView
                clockView
            }
            if let profileModel = selectedProfile {
                profileRecView(profileModel: profileModel)
            }
        }
        .padding(.top, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

extension MeetView {
    
    private var tabView: some View {
        TabView {
            ForEach(vm.fetchWeeklyInvites(), id: \.id) {profileInvite in
                ProfileCard(vm: $vm, profileInvite: profileInvite, selectedProfile: $selectedProfile)
            }

            if !vm.showProfileRecommendations() {
                IntroView(vm: $vm)
            } else {
                ForEach(vm.fetchWeeklyRecs(), id: \.id) {profileInvite in
                    ProfileCard(vm: $vm, profileInvite: profileInvite,  selectedProfile: $selectedProfile)
                }
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
            
            ProfileView(vm: ProfileViewModel(profileModel: profileModel, cacheManager: vm.cacheManager)) {
                withAnimation(.easeInOut(duration: 0.2)) { selectedProfile = nil  }
            }
        }
        .transition(.asymmetric(insertion: .identity, removal: .move(edge: .bottom)))
        .zIndex(1)
    }

    
    
    @ViewBuilder private var clockView: some View {
        if !vm.showRespondToProfilesToRefresh() {
//            if let time = vm.weeklyRecDoc?.endsAt.dateValue() {
//                SimpleClockView(targetTime: time) {
//                    vm.reloadWeeklyRecCycle()
//                }
//            }
        } else {
            Text("Respond to profiles to get new matches")
        }
    }
}
