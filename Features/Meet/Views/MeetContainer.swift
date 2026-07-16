//
//  DailyProfiles.swift
//  Scoop
//
//  Created by Art Ostin on 08/08/2025.
//
import SwiftUI


struct MeetContainer: View {
    
    //Inject Dependencies
    let vm: MeetViewModel

    //Local view state
    @State private var ui = MeetUIState()
    @State private var invite = SendInvitePresenter() //Owns the quick-invite card open/close flight
    @State private var isAtTopOfScroll = true


    var body: some View {
        NavigationStack {
            TabScrollView(type: .meet, showEmptyView: vm.profiles.isEmpty) {
                profileList
            }
            .isAtTopOfScroll($isAtTopOfScroll)
        }
        .overlay(alignment: .topTrailing) {infoButton}
        .environment(invite) //So each ProfileCard's .sendInviteSource reports its frame to the presenter

        //Different sub views of meetContainer
        .inviteView(presentedID: invite.presentedID) {inviteOverlay}
        .responseCover(presentedID: ui.respondedToProfile) {RespondedToProfileCover(responseType: $0)}
        .fullScreenCover(isPresented: $ui.showInfo) {MeetInfo()}
    }
}

//1. Profile View Logic
extension MeetContainer {
    
    private var profileList: some View {
        LazyVStack(spacing: Spacing.xxxl) {
            ForEach(vm.profiles) { profile in
                profileCard(profile)
            }
        }
    }
        
    private func profileView(_ profile: UserProfile) -> some View {
        ProfileContainer(
            vm: ProfileViewModel(profile: profile, imageLoader: vm.imageLoader, defaults: vm.defaults),
            profileImages: vm.profileImages[profile.id] ?? seedImages(for: profile),
            mode: inviteMode(for: profile),
            onDismiss: { ImageZoom.dismiss() }
        )
    }
    
    private func profileCard(_ profile: PendingProfile)-> some View {
        ProfileCard(
            profile: profile,
            quickInviteHidden: invite.isPresenting(profile.id),
            onTap: {image in openProfile(profile, image: image)},
            onQuickInvite: {image in openQuickInvite(profile, image: image)}
        )
        .task { await vm.loadProfileImages(profile: profile.profile) }
    }

    private var infoButton: some View {
        InfoButton(showScreen: $ui.showInfo, isAtTopOfScroll: isAtTopOfScroll && !invite.expanded)
    }
}


//3. Quick Invite Logic
extension MeetContainer {
    
    private func openQuickInvite(_ profile: PendingProfile, image: UIImage) {
        invite.open(profile, image: image) //Presenter looks up the source frame from .sendInviteSource reports
    }
    
    @ViewBuilder
    private var inviteOverlay: some View {
        if let pending = invite.pending, let image = invite.image {
            SendInviteOverlay(
                presenter: invite,
                vm: TimeAndPlaceViewModel(inviteModel: inviteModel(pending), defaults: vm.defaults),
                image: image,
                images: vm.profileImages[pending.profile.id] ?? [image],
                details: profileDetails(pending.profile),
                sendInvite: {sendInvite(pending, draft: $0)},
                declineProfile: {
                    Task { await respondToProfile(profile: pending.profile) }
                }
            )
        }
    }

    //Must match ProfileCard's info line exactly — the flight chrome fades it out in place.
    private func profileDetails(_ p: UserProfile) -> String {
        "\(p.year) | \(p.degree) | \(p.hometown)"
    }

    private func inviteModel(_ profileEvent: PendingProfile) -> InviteContext {
        InviteContext(profileId: profileEvent.id, name: profileEvent.profile.name, image: profileEvent.image)
    }
}

//Key Functions
extension MeetContainer {

    
    private func seedImages(for profile: UserProfile) -> [UIImage] {
        vm.profiles.first { $0.profile.id == profile.id }.map { [$0.image] } ?? []
    }
    
    
    //The profile zooms out of the card image (ImageZoom / native UIKit zoom);
    //drag-down and the X both zoom it back in.
    private func openProfile(_ profile: PendingProfile, image: UIImage) {
        guard !ImageZoom.isPresented, !invite.expanded else { return }
        ImageZoom.present(sourceID: profile.profile.id) { profileView(profile.profile) }
    }

    private func hideProfileAndInviteInBackground() {
        ImageZoom.dismiss(animated: false) //Instant: the response cover is already open above
        invite.reset()
    }
        
}

//Logic of actually responding to a profile
extension MeetContainer {
    
    private func sendInvite(_ profileEvent: PendingProfile, draft: EventFieldsDraft) {
        Task {await respondToProfile(event: draft, profile: profileEvent.profile)}
    }
    
    private func inviteMode(for profile: UserProfile) -> ProfileMode {
        return .sendInvite { draft in
            Task {await respondToProfile(event: draft, profile: profile)}
        } onDecline: {
            Task { await respondToProfile(profile: profile) }
        }
    }
    
    private func submitResponse(event: EventFieldsDraft? = nil, profile: UserProfile) async {
        if let event {
            try? await vm.sendInvite(event: event, profile: profile)
        } else {
            try? await vm.declineProfile(profile: profile)
        }
    }

    
    private func respondToProfile(event: EventFieldsDraft? = nil, profile: UserProfile) async {
        //Step 1: Min time for whole process 0.85 seconds
        async let minDelay: Void = Task.sleep(for: .milliseconds(850))
        
        //Step 2: Show respond fullScreencover. Animation to open takes 0.2
        ui.respondedToProfile = event == nil ? .decline : .newInvite

        //Step 3: Step 3: After 0.2s, dismiss the profile and invite popups beneath the respond cover
        try? await Task.sleep(for: .milliseconds(200))
        hideProfileAndInviteInBackground()
        
        //Step 4: Actually send invite or decline profile
        await submitResponse(event: event, profile: profile)

        //Step 5: Once minimum of 0.85 seconds done, dismiss the screen
        try? await minDelay
        ui.respondedToProfile = nil
    }
}

