//
//  ProfileDetailsView.swift
//  Scoop
//
//  Created by Art Ostin on 23/06/2025.

import SwiftUI
import SwiftUIFlowLayout

//The profile's detail sections, laid out inline below the image pager — the
//containing ProfileContainer scroll owns all scrolling.
struct ProfileDetailsView: View {

    //Injected
    @Bindable var vm: ProfileViewModel
    let p: UserProfile
    let event: UserEvent?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            eventInvite
            DetailsSection(color: keyInfoStrokeColour, title: "About") {UserKeyInfo(p: p)}
            PromptView(prompt: p.prompt1)
            profileInterests
            PromptView(prompt: p.prompt2)
            DetailsSection(title: "Extra Info", adaptivePadding: true) {DetailsExtraInfo(p: p)}
            if !p.prompt3.response.isEmpty {PromptView(prompt: p.prompt3)}
        }
    }
}

extension ProfileDetailsView {

    @ViewBuilder private var eventInvite: some View {
        if let event = event, event.status == .accepted {
            DetailsSection(
                color: .successGreen,
                title: "event with \(event.otherUserName)",
                adaptivePadding: true,
                padding: Spacing.sm
            ) {
                ProfileInviteView(event: event)
            }
            .padding(.bottom, Spacing.xl)
        }
    }

    private var keyInfoStrokeColour: Color {
        vm.viewProfileType == .accept ? Color.successGreen : Color.accent
    }

    private var profileInterests: some View {
        DetailsSection(color: .border, title: "Interests & Character") {
            UserInterests(p: p)
                .padding(.vertical, -12)
        }
    }
}
