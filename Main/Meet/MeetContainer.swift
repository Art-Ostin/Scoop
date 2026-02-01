//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

//@State var showProfileTest: ProfileModel?
//@State private var profilePath: [ProfileModel] = []


struct MeetContainer: View {
    let vm: MeetViewModel
    @State private var ui = MeetUIState()
    @State var imageSize: CGFloat = 0
    @State var profileImages: [String : [UIImage]] = [:]
    @State var dismissOffset: CGFloat? = nil //Fixes bug by controlling dismiss Offset here
    
    init(vm: MeetViewModel) { self.vm = vm }
    
    var body: some View {
            ZStack {
                CustomTabPage(page: .Meet,TabAction: $ui.showInfo) {
                    profileRecSection(profiles: vm.profiles)
                    meetInfo
                }
                .id(vm.profiles.count)
                
                if let profileModel = ui.selectedProfile {
                    ProfileView(vm: ProfileViewModel(profileModel: profileModel, imageLoader: vm.imageLoader),meetVM: vm, profileImages: profileImages[profileModel.id] ?? [],selectedProfile: $ui.selectedProfile, dismissOffset: $dismissOffset)
                        .id(profileModel.id)
                        .zIndex(1)
                        .transition(.move(edge: .bottom))
                }
                
                if let currentProfile = ui.quickInvite {
                    SelectTimeAndPlace(profile: currentProfile, onDismiss: { ui.quickInvite = nil}) { event in
                        try? await vm.updateProfileRec(event: event, profileModel: currentProfile, status: .invited)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $ui.showPendingInvites) {pastInviteView}
            .measure(key: ImageSizeKey.self) { $0.size.width }
            .onPreferenceChange(ImageSizeKey.self) {screenSize in
                imageSize = screenSize - (16 * 2)
            }        
    }
}

extension MeetContainer {
    
    private var meetInfo: some View {
        VStack(spacing: 60) {
            MeetSuggestionView(user: vm.user, showIdealMeet: $ui.showIdealTime)
            newProfileTimer
            DefaultAppButton(image: Image("PastInvites"), size: 25, isPresented: $ui.showPendingInvites)
                .offset(y: -12)
        }
    }
    
    private func profileRecSection(profiles: [ProfileModel]) -> some View {
        LazyVStack(spacing: 72) {
            ForEach(profiles) { profile in
                ProfileCard(profile: profile, size: imageSize, vm: vm, quickInvite: $ui.quickInvite)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if ui.selectedProfile == nil {
                            dismissOffset = nil
                            ui.selectedProfile = profile
                        }
                    }
                    .task {
                        let loadedImages = await vm.loadImages(profileModel: profile)
                        await MainActor.run {
                            profileImages[profile.id] = loadedImages
                        }
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
    
    
    private var pastInviteView: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 48) {
                    ForEach(vm.pendingInvites) { profileModel in
                        PendingInviteCard(
                            profile: profileModel,
                            showPendingInvites: $ui.showPendingInvites,
                            openPastInvites: $ui.openPastInvites
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
