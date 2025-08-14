//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

struct MeetView: View {
    
    @State var vm: MeetViewModel
    @State var selectedProfile: UserProfile?
    @State var selectedInvite: EventInvite?
    
    init(dep: AppDependencies) { _vm = State(initialValue: MeetViewModel(dep: dep))}
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 36) {
                Text("Meet")
                    .font(.body(32, .bold))
                
                tabView
                
                if let target = vm.time {
                    SimpleClockView(targetTime: target) {
                        vm.dep.defaultsManager.removeAllSuggestedProfiles()
                        vm.dep.defaultsManager.clearSuggestedProfilesTimer()
                        vm.profileRecs = []
                        vm.time = nil
                    }
                }
            }
            if let invite = selectedInvite {
                profileInviteView(invite)
            }
            
            if let profile = selectedProfile {
                profileRecView(profile)
            }
        }
        .task {
            if vm.profileRecs.isEmpty { await vm.loadProfileRecs() }
            if vm.profileInvites.isEmpty { await vm.loadEventInvites() }
        }
        .padding(.top, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(vm)
    }
}

extension MeetView {
    
    private var tabView: some View {
        TabView{
            ForEach(vm.profileInvites, id: \.id) {invite in
                ProfileCard(userEvent: invite.event, profile: invite.profile, dep: vm.dep, selectedProfile: $selectedProfile, selectedInvite: $selectedInvite)
            }
            if vm.time == nil {
                IntroView(vm: $vm)
            } else {
                ForEach(vm.profileRecs) {profile in
                    ProfileCard(profile: profile, dep: vm.dep,  selectedProfile: $selectedProfile, selectedInvite: $selectedInvite)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func profileRecView(_ profile: UserProfile) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { }
            ProfileView(profile: profile, dep: vm.dep) {
                withAnimation(.easeInOut(duration: 0.2)) { selectedProfile = nil }
            }
        }
        .transition(.asymmetric(insertion: .identity, removal: .move(edge: .bottom)))
        .zIndex(1)
    }

    private func profileInviteView(_ invite: EventInvite) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { }
            ProfileView(profile: invite.profile, dep: vm.dep, event: invite.event) {
                withAnimation(.easeInOut(duration: 0.2)) { selectedInvite = nil }
            }
        }
        .transition(.asymmetric(insertion: .identity, removal: .move(edge: .bottom)))
        .zIndex(1)
    }
}
