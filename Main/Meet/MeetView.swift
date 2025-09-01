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
    @State var showIdealTime: Bool = false
    
    init(vm: MeetViewModel) { _vm = State(initialValue: vm) }
    
    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 36) {
                        
                        profileScroller
                            .padding(.top, 36)
                        
                        clockView
                        
                    }
                }
                .navigationTitle("Meet")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: "info.circle")
                            .font(.body(17, .bold))
                    }
                }
            }
            
            if let profileModel = selectedProfile {
                profileRecView(profileModel: profileModel)
            }
            if showIdealTime {
                Rectangle()
                    .fill(.thinMaterial)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { showIdealTime = false }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                SelectTimeAndPlace(vm: TimeAndPlaceViewModel(text: "Find Profiles") { event in
                    Task {
                        try await vm.saveIdealMeetUp(event: event)
                        try await vm.createWeeklyCycle()
                    }
                })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

extension MeetView {
    
    @ViewBuilder
    private var profileScroller: some View {

        ScrollView {
            ForEach(vm.invites) { profileInvite in
                ProfileCard(vm: vm, profile: profileInvite, selectedProfile: $selectedProfile)
            }
            
            if !vm.invites.isEmpty {SoftDivider()}
            
            if vm.showProfilesState != .closed {
                VStack(spacing: 48) {
                    ForEach(vm.profiles) { profileInvite in
                            ProfileCard(vm: vm, profile: profileInvite, selectedProfile: $selectedProfile)
                    }
                }
            } else {
                IntroView(vm: vm, showIdealTime: $showIdealTime)
            }
        }
        
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

//HStack {
//    Text("Meet")
//        .font(.body(28, .bold))
//    Spacer()
//    Image(systemName: "info.circle")
//        .font(.body(17, .bold))
//}
