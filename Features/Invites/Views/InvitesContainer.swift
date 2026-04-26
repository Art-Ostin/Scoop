//
//  InvitesContainer.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI


struct InvitesContainer: View {
    
    @State var ui = InvitesUIState()
    
    @State var vm: InvitesViewModel
    @State var profileImages: [String : [UIImage]] = [:]
    @State var showTint: Bool = false
    @State var showTimePopup: Bool = false
    @State var hideInviteTitle: Bool = false
    
    @State var showConfirmAccept: String? = nil
    @State var showConfirmNewTime: String? = nil
    @State var showConfirmNewInvite: String? = nil
    
    var isPopup: Bool {
        showConfirmAccept != nil || showConfirmNewTime != nil || showConfirmNewInvite != nil
    }
    
    var body: some View {
        if vm.invites.isEmpty {
            invitesPlaceholder
        } else {
            ZStack {
                invitesView
                if let profile = ui.selectedProfile { profileView(profile: profile)}
                
                if ui.quickInvite { quickInvite }
                
                if let response = ui.respondedToProfile {
                    RespondedToProfileView(response: response)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .customAlert(item: $showConfirmNewTime, title: "New Times Proposed", cancelTitle: "Cancel", okTitle: "I Understand", message: "If they accept one of your proposed times & you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) { profileId in
                Task {
                    try? await respondWithNewTime(profileId: profileId)
                }
            }
            .customAlert(item: $showConfirmAccept, title: "Event Commitment", cancelTitle: "Cancel", okTitle: "I Understand", message: "You are committing to meet on x at. If you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) { profileId in
            }
            .customAlert(item: $showConfirmNewInvite, title: "Event Commitment", cancelTitle: "Cancel", okTitle: "I Understand", message: "You are committing to meet on  at. If you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) { profileId in
                Task {
                    try await respondWithNewTime(profileId: profileId)
                }
            }
            
            .onPreferenceChange(IsTimeOpen.self) { newValue in
                showTimePopup = newValue
            }
            .hideTabBar(hideBar: isPopup)
        }
    }
}

extension InvitesContainer {

    private func fetchEventProfile(_ profile: UserProfile) -> EventProfile? {
        vm.invites.first { $0.profile.id == profile.id }
    }

    private var invitesView: some View {
        VStack(spacing: 20) {
            titleAndTab
                .opacity(showTimePopup ? (hideInviteTitle ? 0.03 : 0.2) : 1)
            
            ForEach(vm.invites, id: \.self) { invite in
                
                InviteCard(
                    showQuickInvite: $ui.profileInvite,
                    vm: vm.respondVM(for: invite, image: profileImages[invite.profile.id]?.first ?? UIImage()),
                    ui: ui,
                    eventProfile: invite,
                    showTimePopup: showTimePopup,
                    showAcceptInvite: $showConfirmAccept,
                    showNewTimeInvite: $showConfirmNewInvite) { profile in
                        openProfile(profile)
                    } onDecline: { userEvent in
                        Task {
                            try await respondToProfile(respondType: .decline, profileId: invite.profile.id)
                        }
                    }
                    .task { await loadProfileImages(invite.profile) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .background(Color.background)
        .onPreferenceChange(QuickInviteTime.self) { newValue in
                showTint = newValue
        }
        .onPreferenceChange(HideInvitePreferenceKey.self) { newValue in
            hideInviteTitle = newValue
        }
        .animation(.easeInOut(duration: 0.15), value: showTimePopup)
        .animation(.easeInOut(duration: 0.15), value: hideInviteTitle)

    }
    
    private var titleAndTab: some View {
        ZStack(alignment: .top) {
            Text("Invites")
                .font(.custom("SFProRounded-Bold", size: 32))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 60)
            
            TabInfoButton(showScreen: $ui.showDetails)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    private var invitesPlaceholder: some View {
        Text("There are no current invites")
    }
}
//ProfileView Related
extension InvitesContainer {
    
    @ViewBuilder
    private func profileView(profile: UserProfile) -> some View {
        if let eventProfile = fetchEventProfile(profile) {
            ProfileView(
                vm: ProfileViewModel(
                    defaults: vm.defaults,
                    s: vm.session,
                    profile: eventProfile.profile,
                    event: eventProfile.event,
                    imageLoader: vm.imageLoader
                ),
                profileImages: profileImages[eventProfile.profile.id] ?? [],
                selectedProfile: $ui.selectedProfile,
                dismissOffset: $ui.dismissOffset, profileResponse:  {respondType in
                    Task {
                        try? await respondToProfile(respondType: respondType, profileId: eventProfile.profile.id)
                    }
                })
                .id(eventProfile.profile.id)
                .zIndex(1)
                .transition(.move(edge: .bottom))
        }
    }
    
    @ViewBuilder
    private var quickInvite: some View {
        if let profile = ui.profileInvite {
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(
                    defaults: vm.defaults,
                    sessionManager: vm.session,
                    profile: profile,
                    image: profileImages[profile.id]?.first ?? UIImage()
                ),
                showInvite: $ui.quickInvite,
                isNewEvent: true) { draft in
                    Task {
                        try await respondWithEvent(profileId: profile.id)
                    }
                }
            }
        }
    
    private func openProfile(_ profile: UserProfile) {
        if ui.selectedProfile == nil {
            ui.dismissOffset = nil
            ui.selectedProfile = profile
        }
    }
    
    private func loadProfileImages(_ profile: UserProfile) async {
        let loadedImages = await vm.loadImages(profile: profile)
        profileImages[profile.id] = loadedImages
    }
    
}

//Responding to Profile View
extension InvitesContainer {
    
    private func respondToProfile(respondType: ProfileResponse, profileId: String) async throws {
        async let minDelay: Void = Task.sleep(for: .milliseconds(750))
        try await respondToProfileAction(respondType: respondType, profileId: profileId)
        
        ui.respondedToProfile = respondType
        try? await Task.sleep(for: .milliseconds(550))
        ui.selectedProfile = nil
        //4.if the minimum of 0.75s done, dismiss the screen overlay
        try? await minDelay
        ui.respondedToProfile = nil
    }
    
    private func respondToProfileAction (respondType: ProfileResponse, profileId: String) async throws {
        switch respondType {
        case .accepted:
            try await acceptInvite(profileId: profileId)
        case .newTime:
            try await respondWithNewTime(profileId: profileId)
        case .newInvite:
            try await  respondWithEvent(profileId: profileId)
        case .decline:
            try await declineInvite(profileId: profileId)
        }
    }
        
    private func respondWithNewTime(profileId: String) async throws {
        if let newTime = vm.respondVMs[profileId]?.respondDraft.newTime {
            let rescheduleResponse = RescheduleResponse(eventId: newTime.event.id, userId: vm.userId, recipientId: newTime.event.otherUserId, oldTimes: newTime.event.proposedTimes, newTimes: newTime.proposedTimes)
                try await vm.sendNewTime(rescheduleResponse: rescheduleResponse)
        }
    }
    
    private func respondWithEvent(profileId: String) async throws {
        //1. From profileId, construct a eventResponse
        if let respondDraft = vm.respondVMs[profileId]?.respondDraft {
            let eventResponse = EventResponse(oldEvent: respondDraft.originalInvite.event, newEvent: respondDraft.newEvent, userId: vm.userId)
            try await vm.sendNewEvent(eventResponse: eventResponse)
        }
    }
    
    private func acceptInvite(profileId: String) async throws {
        if let originalInvite = vm.respondVMs[profileId]?.respondDraft.originalInvite, let selectedDay = originalInvite.selectedDay {
            try await vm.acceptInvite(eventId: originalInvite.event.id, senderId: vm.userId, acceptedDate: selectedDay)
        }
    }
    
    private func declineInvite(profileId: String) async throws {
        if let eventId = vm.respondVMs[profileId]?.respondDraft.originalInvite.event.id {
            try await vm.declineInvite(eventId: eventId, otherUserId: profileId)
        }
    }
}

/*
 respondType: ProfileResponse,
 event: EventDraft? = nil,
 originalInvite: OriginalInvite? = nil,
 newTime: NewTimeDraft? = nil,
 profile: UserProfile? = nil
) async {
 async let minDelay: Void = Task.sleep(for: .milliseconds(750))
 do {
     try await respondToProfileActions(respondType: respondType, event: event, originalInvite: originalInvite, newTime: newTime, profile: profile)
 } catch {
     print("Error Thrown: \(error)")
 }
 ui.respondedToProfile = respondType
 try? await Task.sleep(for: .milliseconds(550))
 ui.selectedProfile = nil
 //4.if the minimum of 0.75s done, dismiss the screen overlay
 try? await minDelay
 ui.respondedToProfile = nil
}
 */

/*
 private func respondToProfileActions(
     respondType: ProfileResponse,
     event: EventDraft?,
     originalInvite: OriginalInvite?,
     newTime: NewTimeDraft?,
     profile: UserProfile?
 ) async throws {
     switch respondType {
     case .accepted:
         
         if let originalInvite, let day = originalInvite.selectedDay {
             try await vm.acceptInvite(eventId: originalInvite.event.id, senderId: originalInvite.event.otherUserId, acceptedDate: day)
         }
     case .newTime:
         if let newTime {
             try await vm.sendNewTime(rescheduleResponse: RescheduleResponse(eventId: newTime.event.id, userId: vm.userId, recipientId: newTime.event.otherUserId, oldTimes: newTime.event.proposedTimes, newTimes: newTime.proposedTimes))
         }
     case .newInvite:
         if let event {
             try await vm.sendInvite(eventId: <#T##String#>)
         } else  {
             print("No Event to pass in")
         }
     case .decline:
         if let event = profile?.id {
             try await vm.declineInvite(eventId: event.)
         }
     }
 }
 */

/*
 //
 //
 //                if let acceptedInvite = vm.respondVMs[profileId]?.respondDraft.originalInvite {
 //
 //
 //                    Task {
 //
 //
 //
 //                        try? await vm.acceptInvite(acceptedInvite: acceptedInvite)
 //                    }
 //                } else {
 //                    print("Id not located")
 //                }

 */

/*
 
 
 acceptedInvite in
 Task {
     await respondToProfile(respondType: .accepted, originalInvite: acceptedInvite, profile: profile)
 }
} sendNewTime: { newTime in
 Task {
     await respondToProfile(respondType: .newTime, newTime: newTime, profile: profile)
 }
} sendInvite: { eventDraft in
 Task {
     await respondToProfile(respondType: .newInvite, event: eventDraft, profile: profile)
 }
} declineInvite: { userEvent in
 Task {
     await respondToProfile(respondType: .decline, profile: profile)
 }
}

 */
