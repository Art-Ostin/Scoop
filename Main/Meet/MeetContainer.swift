//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

//@State var showProfileTest: ProfileModel?


struct MeetContainer: View {
    @Bindable var vm: MeetViewModel
    @State var selectedProfile: ProfileModel?
    
    @State var showIdealTime: Bool = false
    @State var quickInvite: ProfileModel?
    @State var showPendingInvites = false
    @State var showInfo: Bool = false
    
    @State var openPastInvites = false
    @State var imageSize: CGFloat = 0
    
    @Namespace private var zoomNS
    
    
    init(vm: MeetViewModel) { self.vm = vm }
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                CustomTabPage(page: .Meet,TabAction: $showInfo) {
                    profileScroller
                    meetInfo
                }
                .id(vm.profiles.count)
                
                
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $showPendingInvites) {pastInviteView}
            .onChange(of: selectedProfile) {oldValue, newValue in
                if newValue != nil && openPastInvites {
                    withAnimation(.spring(duration: 0.1)) {showPendingInvites = true }
                    openPastInvites = false
                }
            }
            .measure(key: ImageSizeKey.self) { $0.size.width }
            .onPreferenceChange(ImageSizeKey.self) {screenSize in
                imageSize = screenSize - (24 * 2)
            }
            
        }
    }
}

extension MeetContainer {
    
    private var meetInfo: some View {
        VStack(spacing: 60) {
            MeetSuggestionView(user: vm.user, showIdealMeet: $showIdealTime)
            newProfileTimer
            DefaultAppButton(image: Image("PastInvites"), size: 25, isPresented: $showPendingInvites)
                .offset(y: -12)
        }
    }
    
    private func profileList(_ items: [ProfileModel]) -> some View {
        LazyVStack(spacing: 84) {
            ForEach(items) { profileModel in
                NavigationLink {
                    ProfileView(vm: ProfileViewModel(profileModel: profileModel, cacheManager: vm.cacheManager), meetVM: vm)
                        .navigationTransition(.zoom(sourceID: profileModel.id, in: zoomNS))
                        .toolbar(.hidden, for: .navigationBar)
                } label: {
                    ProfileCard(profile: profileModel, size: imageSize, vm: vm, quickInvite: $quickInvite)
                        .matchedTransitionSource(id: profileModel.id, in: zoomNS)
                }
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
    
    private var profileScroller: some View {
        VStack(spacing: 0) {
            profileList(vm.invites)
            if  vm.showProfilesState != .closed {
                profileList (vm.profiles)
            } else {
                IntroView(vm: vm, showIdealTime: $showIdealTime)
            }
        }
        .padding(.bottom, 36)
    }
    
    @ViewBuilder
    private var clockView: some View {
        if let time = vm.endTime, vm.showProfilesState == .active {
            SimpleClockView(targetTime: time) {}
        } else if vm.showProfilesState == .respond {
            Text("Respond to Refresh")
        }
    }
    
    private var pastInviteView: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 48) {
                    ForEach(vm.pendingInvites) { profileModel in
                        PendingInviteCard(
                            profile: profileModel,
                            selectedProfile: $selectedProfile,
                            showPendingInvites: $showPendingInvites,
                            openPastInvites: $openPastInvites
                        )
                    }
                }
            }
            .navigationTitle("Your Pending Invites")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/*
 if let profileModel = selectedProfile {
     ProfileView(vm: ProfileViewModel(profileModel: profileModel, cacheManager: vm.cacheManager), meetVM: vm, selectedProfile: $selectedProfile)
         .id(profileModel.id)
         .transition(.move(edge: .bottom))
         .zIndex(1)
 }

 */

/*
 private func profileList(_ items: [ProfileModel]) -> some View {
     LazyVStack(spacing: 84) {
         ForEach(items) { profileInvite in
             ProfileCard(profile: profileInvite, size: imageSize, vm: vm, quickInvite: $quickInvite, selectedProfile: $selectedProfile)
         }
     }
 }
 */
