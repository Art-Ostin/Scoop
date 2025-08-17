//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

struct MeetView: View {
    
    @State var vm: MeetViewModel
    
    let dep: AppDependencies
    
    @State var selectedProfile: EventInvite?
    
    init(dep: AppDependencies) {
        self.dep = dep
        self._vm = State(initialValue: MeetViewModel(dep: dep))
    }
    
    var body: some View {
        
        ZStack {
            
            VStack(spacing: 36) {
                Text("Meet")
                    .font(.body(32, .bold))

                tabView
                
                clockView
                
            }
            
        }
        .padding(.top, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(vm)
    }
}


extension MeetView {
    
    private var tabView: some View {
        TabView {
            ForEach(dep.sessionManager.profileInvites, id: \.id) {invite in
                ProfileCard(event: invite.event, profile: invite.profile, dep: vm.dep, selectedProfile: $selectedProfile)
            }
            if !vm.showWeeklyRecs {
                IntroView(vm: $vm)
            } else {
                ForEach(dep.sessionManager.profileRecs, id: \.id) {profileRec in
                    ProfileCard(profile: profileRec.profile, dep: vm.dep,  selectedProfile: $selectedProfile)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    
    private func profileRecView(profile: UserProfile, event: UserEvent? = nil) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { }
            
            if let event = event {
                ProfileView(profile: profile, dep: dep, event: event) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedProfile = nil  }
                }
            } else {
                ProfileView(profile: profile, dep: dep) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedProfile = nil  }
                }
            }
        }
        .transition(.asymmetric(insertion: .identity, removal: .move(edge: .bottom)))
        .zIndex(1)
    }
    
    @ViewBuilder private var clockView: some View {
        if !vm.showRespondToProfilesToRefresh {
            if let time = vm.weeklyRecDoc?.endsAt.dateValue() {
                SimpleClockView(targetTime: time) {
                    vm.reloadWeeklyRecCycle()
                }
            }
        } else {
            Text("Respond to profiles to get new matches")
        }
    }
}
