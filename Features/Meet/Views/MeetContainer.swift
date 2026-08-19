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


//Logic of actually responding to a profile
extension MeetContainer {
    
    private func inviteMode(for profile: UserProfile) -> ProfileMode {
        return .sendInvite { draft, sendFlight in
            respondToProfile(event: draft, profile: profile, sendFlight: sendFlight)
        } onDecline: { declineSource in
            respondToProfile(profile: profile, declineSource: declineSource)
        }
    }
    
    private func submitResponse(event: EventFieldsDraft? = nil, profile: UserProfile) async {
        if let event {
            try? await vm.sendInvite(event: event, profile: profile)
        } else {
            try? await vm.declineProfile(profile: profile)
        }
    }
    
    
    private func respondToProfile(event: EventFieldsDraft? = nil, profile: UserProfile,
                                  declineSource: CGRect? = nil, sendFlight: SendInviteFlightSource? = nil) {
        let cover = responseCover?.show(event == nil ? .decline : .newInvite, from: declineSource, sendFlight: sendFlight)

        Task {
            //Step 2: Minimum time the cover stays on screen. The decline flight rests at
            //~1.02s + mount latency; 1.4 keeps ~0.3s of landed stillness before the exit.
            async let minDelay: Void = Task.sleep(for: event == nil ? .seconds(1.4) : .seconds(3.5))

            //Step 3: Once the cover is opaque, dismiss the quick invite beneath it. Held past the
            //cover's own fade-in — dismissing mid-morph shows the profile collapsing through it.
            try? await Task.sleep(for: BlurCoverMotion.coveredAt)
            ui.showInvite = nil
            
            //Step 4: Actually send invite or decline profile
//            await submitResponse(event: event, profile: profile)
            
            //Step 5: Once the minimum display time is done, fade the cover back out
            try? await minDelay
            responseCover?.close(cover)
        }
    }
}

