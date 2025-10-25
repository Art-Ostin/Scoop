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
    @State var imageWidth: CGFloat = 0
    @State var showPendingInvites = false
    @State var wasInviteSelected = false
    
    init(vm: MeetViewModel) { self.vm = vm }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.background
                ScrollView {
                    VStack(spacing: 36) {
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
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 250, height: 0.5)
                            .background(Color(red: 0.86, green: 0.86, blue: 0.86))
                        
                        MeetSuggestionView(user: vm.user, showIdealMeet: $showIdealTime)
                        
                        pastInvites
                            .offset(y: -12)
                    }
                    .padding(.bottom, 240)
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
                if let profileModel = selectedProfile {
                    ProfileView(vm: ProfileViewModel(profileModel: profileModel, cacheManager: vm.cacheManager), meetVM: vm, selectedProfile: $selectedProfile)
                        .id(profileModel.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .move(edge: .bottom))
                        )
                        .zIndex(1)
                        .ignoresSafeArea()
                }
                
                if let currentProfile = quickInvite {
                    Rectangle()
                        .fill(.thinMaterial)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { quickInvite = nil }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    SelectTimeAndPlace(vm: TimeAndPlaceViewModel(profile: currentProfile, onSubmit: { event in
                        Task { try? await vm.sendInvite(event: event, profileModel: currentProfile) }
                    }))
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
            .onAppear {
                imageWidth = (proxy.size.width - 48)
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
            }
        }
}

extension MeetView {
    @ViewBuilder
    private var profileScroller: some View {
        
        VStack(spacing: 0) {
            VStack(spacing: 84) {
                ForEach(vm.invites) { profileInvite in
                    ProfileCard(vm: vm, profile: profileInvite, quickInvite: $quickInvite, imageWidth: imageWidth)
                        .onTapGesture {
                            withAnimation(.smooth(duration: 0.2)) {
                                selectedProfile = profileInvite
                            }
                        }
                }
            }
            
            if vm.showProfilesState != .closed {
                VStack(spacing: 84) {
                    ForEach(vm.profiles) { profileInvite in
                        ProfileCard(vm: vm, profile: profileInvite, quickInvite: $quickInvite, imageWidth: imageWidth)
                            .onTapGesture {
                                withAnimation(.smooth(duration: 0.2)) {
                                    selectedProfile = profileInvite
                                }
                            }
                    }
                }
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
    
    private var tabTitle: some View {
        HStack (spacing: 12) {
            Text(title)
                .font(.tabTitle())
            
            Spacer()
            
            Image(systemName: "info.circle")
                .font(.body(15))
                .foregroundStyle(Color.black)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 96)
    }
    
    private var pastInvites: some View {
        HStack(alignment: .center) {
            Image("PastInvites")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .padding(6)
                .background(
                    Circle().fill(Color.background)
                )
                .overlay(
                    Circle().strokeBorder(Color.grayBackground, lineWidth: 0.4)
                )
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                .contentShape(Circle())
                .onTapGesture { showPendingInvites = true }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("New Profiles in: ")
                SimpleClockView(targetTime: Calendar.current.date(byAdding: .day, value: 3, to: .now)!) {}
            }
            .font(.body(10, .regular))
            .foregroundColor(Color(red: 0.58, green: 0.58, blue: 0.58))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 36)
    }
}

struct TitleOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
