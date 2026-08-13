//
//  DailyProfiles.swift
//  Scoop
//
//  Created by Art Ostin on 08/08/2025.
//
import SwiftUI


struct MeetContainer: View {
    
    //Inject Dependencies
    @Environment(ResponseCoverPresenter.self) private var responseCover: ResponseCoverPresenter?
    let vm: MeetViewModel

    //Local view state
    @State private var ui = MeetUIState()
    @State private var isAtTopOfScroll = true

    var body: some View {
        ZoomNavigationStack {
            NavigationStack {
                TabScrollView(type: .meet, showEmptyView: vm.profiles.isEmpty) {
                    profileList
                }
                .isAtTopOfScroll($isAtTopOfScroll)
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {infoButton}
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $ui.showInfo) {MeetInfo()}
    }
}

//1. Profile View Logic
extension MeetContainer {
    
    private var profileList: some View {
        LazyVStack(spacing: 84) {
            ForEach(vm.profiles) { profile in
                profileCard(profile)
            }
        }
    }
            
    private func profileCard(_ profile: PendingProfile)-> some View {
        ProfileCard(vm: vm, ui: ui, profile: profile, inviteMode: { inviteMode(for: $0)}) //The send/decline path stays in this container
        .task { await vm.loadProfileImages(profile: profile.profile) }
    }

    private var infoButton: some View {
        InfoButton(
            showScreen: $ui.showInfo,
            isAtTopOfScroll: isAtTopOfScroll && (ui.showInvite == nil)
        )
    }
}


//Key Functions
extension MeetContainer {

    private func hideInviteInBackground() {
        ui.showInvite = nil
    }
}

//Logic of actually responding to a profile
extension MeetContainer {
    
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
        
        //Step 2: Fade the response cover in on the root plane, above the tab bar
        responseCover?.response = event == nil ? .decline : .newInvite

        //Step 3: After 0.2s, dismiss the quick invite beneath the response cover
        try? await Task.sleep(for: .milliseconds(200))
        hideInviteInBackground()
        
        //Step 4: Actually send invite or decline profile
//        await submitResponse(event: event, profile: profile)
        
        //Step 5: Once minimum of 0.85 seconds done, fade the cover back out
        try? await minDelay
        responseCover?.response = nil
    }
}


/*
 
 //Must match ProfileCard's info line exactly — the flight chrome fades it out in place.
 private func profileDetails(_ p: UserProfile) -> String {
     "\(p.year) | \(p.degree) | \(p.hometown)"
 }

 
 
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
 @State private var invite = SendInvitePresenter() //Owns the quick-invite card open/close flight
 //Hopefully remove after
 .environment(invite)
 .inviteView(presentedID: invite.presentedID) {inviteOverlay}

 
 
 
 //The profile zooms out of the card image (ImageZoom / native UIKit zoom);
 //drag-down and the X both zoom it back in.
 private func openProfile(_ profile: PendingProfile, image: UIImage) {
     guard !ImageZoom.isPresented, !invite.expanded else { return }
     ImageZoom.present(sourceID: profile.profile.id) { profileView(profile.profile) }
 }

 */
