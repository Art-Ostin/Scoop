//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI


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
                    if !vm.invites.isEmpty  {
                        VStack(spacing: 24) {
                            
                            
                            VStack(spacing: 24) {
                                sectionTitle(text: "Invites")
                                    
                                profileInviteSection(profiles: vm.invites)
                            }
                                 
                            
                            MapDivider()
                                .padding(.horizontal, 36)
                            
                            VStack(spacing: 24) {
                                sectionTitle(text: "Profiles")
                                

                                
                                profileRecSection(profiles: vm.profiles)
                            }
                            .padding(.top, 4)
                        }
                    } else {
                        profileRecSection(profiles: vm.profiles)
                    }
                    
                    
                    MeetInfoView(vm: vm, ui: ui)
                }
                .id(vm.profiles.count)
                
                if let profileRec = ui.selectedProfile {
                    profile(profile: profileRec)
                }
                
                if let quickInviteProfile = ui.quickInvite {
                    quickInviteView(profile: quickInviteProfile)
                }
                
                if let profileResponse = ui.showSentInvite {
                    RespondToProfileView(isInvite: profileResponse)
                }
            }
            .transition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $ui.showPendingInvites) {PastInviteView(vm: vm, ui: ui)}
            .measure(key: ImageSizeKey.self) { $0.size.width }
            .onPreferenceChange(ImageSizeKey.self) {screenSize in
                imageSize = screenSize - (16 * 2)
            }
    }
}

extension MeetContainer {
    
    
    private func sectionTitle(text: String) -> some View {
        Text(text)
            .font(.body(12, .italic))
            .foregroundStyle(.black)
            .fixedSize(horizontal: true, vertical: false)   
            .overlay(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .frame(height: 1)
                    .offset(y: 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 24)
    }
    
    private func profileRecSection(profiles: [ProfileModel]) -> some View {
        LazyVStack(spacing: 72) {
            profileCardSection(profiles: profiles)
        }
    }
    
    private func profileInviteSection(profiles: [ProfileModel]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ClearRectangle(size: 0)
                HStack(spacing: 12) {
                    profileCardSection(profiles: profiles)
                }
                ClearRectangle(size: 0)
            }
            .frame(height: imageSize + 8, alignment: .top)
        }
    }
    
    
    private func profileCardSection(profiles: [ProfileModel]) -> some View {
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
    
            
    private func profile(profile: ProfileModel) -> some View {
        ProfileView(
            vm: ProfileViewModel(defaults: vm.defaults, sessionManager: vm.s, profileModel: profile, imageLoader: vm.imageLoader), meetVM: vm,
            profileImages: profileImages[profile.id] ?? [],
            selectedProfile: $ui.selectedProfile,
            dismissOffset: $dismissOffset,
            showRespondToProfile: $ui.showSentInvite,
        )
        .id(profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    private func quickInviteView(profile: ProfileModel) ->  some View {
        SelectTimeAndPlace(defaults: vm.defaults, sessionManager: vm.s, profile: profile, onDismiss: { ui.quickInvite = nil}) { event in
            Task{ @MainActor in await sendQuickInvite(event: event, profile: profile)}
        }
    }
    
    func sendQuickInvite(event: EventDraft, profile: ProfileModel) async {
        ui.showSentInvite = true
        
        async let minDelay: Void = Task.sleep(for: .milliseconds(750))

        try? await Task.sleep(for: .milliseconds(750))
        ui.quickInvite = nil
        try? await vm.updateProfileRec(event: event, profileModel: profile, status: .invited)
        try? await minDelay
        ui.showSentInvite = nil
    }
}
