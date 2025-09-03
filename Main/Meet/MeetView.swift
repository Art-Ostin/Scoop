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
    init(vm: MeetViewModel) { self.vm = vm }

    var body: some View {
        
        ZStack {
            ScrollView {
                VStack {
                    
                    Text("Hello World")
                    
                    
                    ForEach(vm.profiles) { profile in
                        Text(profile.profile.name)
                            .foregroundStyle(Color.black)
                    }
//
                    
                      tabTitle
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: ScrollViewOffsetPreferenceKey.self, value: proxy.frame(in: .global).maxY)
                             }
                        )
                    
//                    profileScroller
       
                    clockView
                    
                }
            }
            .id(vm.profiles.count)

            .overlay(Text("\(scrollViewOffset)"))
            .onAppear {
                for profile in vm.profiles {
                    print(profile.profile.name)
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
        .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
            scrollViewOffset = value
        }
    }
}


extension MeetView {
    
    @ViewBuilder
    private var profileScroller: some View {
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
    
    private var tabTitle: some View {
        Text(title)
            .font(.tabTitle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
    }
    
    private var navBarLayer: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(Color.blue)
    }
}



struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
