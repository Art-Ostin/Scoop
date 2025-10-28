//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

struct MeetView: View {
    @State private var scrollViewOffset: CGFloat = 0
    @State private var title: String  = "Meet"
    @Bindable var vm: MeetViewModel
    @State var selectedProfile: ProfileModel?
    @State var endTime: Date?
    @State var showIdealTime: Bool = false
    @State var quickInvite: ProfileModel?
    @State var showPendingInvites = false
    @State var wasInviteSelected = false
    @State var showTabAction = false
    @State var showProfileTest: ProfileModel?
    @State var imageWidth: CGFloat = 0
    @State var showInfo: Bool = false
    
    
    init(vm: MeetViewModel) { self.vm = vm }
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.background
                ScrollView {
                    VStack(spacing: 24) {
                        VStack {
                            TabButton(image: Image(systemName: "info.circle"), isPresented: $showInfo)
                            TabTitle(page: .meet, offset: $scrollViewOffset)
                        }
                        profileScroller
                        CustomDivider()
                        VStack(spacing: 60) {
                            MeetSuggestionView(user: vm.user, showIdealMeet: $showIdealTime)
                            newProfileTimer
                            DefaultAppButton(image: Image("PastInvites"), size: 25, isPresented: $showPendingInvites)
                                .offset(y: -12)
                        }
                    }
                    .padding(.bottom, 108)
                }
                .id(vm.profiles.count)
                .tabViewModifiers(page: .meet, scrollViewOffset: $scrollViewOffset)
                
                if let profileModel = selectedProfile {
                    ProfileView(vm: ProfileViewModel(profileModel: profileModel, cacheManager: vm.cacheManager), meetVM: vm, selectedProfile: $selectedProfile)
                        .id(profileModel.id)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                        .ignoresSafeArea()
                }
                if let currentProfile = quickInvite {
                    SelectTimeAndPlace(profile: currentProfile, onDismiss: { quickInvite = nil}) { event in
                        try? await vm.sendInvite(event: event, profileModel: currentProfile)
                    }
                }
                if showIdealTime {
                    SelectTimeAndPlace(text: "Find Profiles", onDismiss: { showIdealTime = false }) { event in
                        try? await vm.saveIdealMeetUp(event: event)
                        try? await vm.createWeeklyCycle()
                    }
                }
            }
            .onAppear {
                imageWidth = proxy.size.width - 48
            }
            .sheet(isPresented: $showPendingInvites) {
                NavigationStack {
                    PendingInviteView(showInvitedProfile: $selectedProfile, vm: vm, showPendingInvites: $showPendingInvites, wasInviteSelected: $wasInviteSelected)
                        .navigationTitle("Your Pending Invites")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: selectedProfile) { oldValue, newValue in
                guard newValue == nil, wasInviteSelected else { return }
                withAnimation(.spring(duration: 0.1)) {showPendingInvites = true }
                wasInviteSelected = false
            }
            .animation(.smooth(duration: 0.2), value: selectedProfile)
        }
    }
}

extension MeetView {
    
    @ViewBuilder private func profileList(_ items: [ProfileModel]) -> some View {
        LazyVStack(spacing: 84) {
            ForEach(items) { profileInvite in
                ProfileCard(vm: vm, profile: profileInvite, quickInvite: $quickInvite, selectedProfile: $selectedProfile, imageWidth: imageWidth)
            }
        }
    }
    
    private var newProfileTimer: some View {
        HStack(spacing: 0) {
            Text("new profiles in: ")
                .foregroundStyle(Color.grayText)
            SimpleClockView(targetTime: Calendar.current.date(byAdding: .day, value: 3, to: .now)!) {}
        }
        .font(.body(14))
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    private var profileScroller: some View {
        VStack(spacing: 0) {
            profileList(vm.invites)
            if  vm.showProfilesState != .closed {
                profileList (vm.profiles)
            } else {
                IntroView(vm: vm, showIdealTime: $showIdealTime)
            }
        }
    }
    
    @ViewBuilder private var clockView: some View {
        if let time = vm.endTime, vm.showProfilesState == .active {
            SimpleClockView(targetTime: time) {}
        } else if vm.showProfilesState == .respond {
            Text("Respond to Refresh")
        }
    }
}
