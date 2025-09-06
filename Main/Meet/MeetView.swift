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
                VStack(spacing: 32) {
                      tabTitle
                        .opacity(Double(scrollViewOffset) / 70)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: TitleOffsetKey.self,
                                    value: proxy.frame(in: .global).maxY
                                )
                             }
                        )
                    profileScroller
                    clockView
                }
            }
            .overlay(alignment: .top) {
                ScrollNavBar(title: "Meet")
                    .opacity(withAnimation { scrollViewOffset < 0 ? 1 : 0 } )
                    .ignoresSafeArea(edges: .all)
            }
            
            .onPreferenceChange(TitleOffsetKey.self) { y in
                scrollViewOffset = y
            }
            .id(vm.profiles.count)
            .overlay(Text("\(scrollViewOffset)"))
            
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
        HStack {
            Text(title)
                .font(.tabTitle())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Image(systemName: "info.circle")
                .font(.body(17))
        }
        .padding(.horizontal, 32)
        .padding(.top, 60)
    }
}

struct TitleOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
