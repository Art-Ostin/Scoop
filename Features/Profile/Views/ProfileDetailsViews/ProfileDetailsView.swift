//
//  pDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.

import SwiftUI
import SwiftUIFlowLayout



struct ProfileDetailsView: View {
    @Bindable var vm: ProfileViewModel
    @Bindable var ui: ProfileUIState    
    
    let p: UserProfile

    let event: UserEvent?
    let detailsOpen: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ClearRectangle(size: 24)
                eventInvite
                DetailsSection(color: keyInfoStrokeColour, title: "About") {UserKeyInfo(p: p)}
                PromptView(prompt: p.prompt1)
                profileInterests
                PromptView(prompt: p.prompt2)
                DetailsSection(title: "Extra Info", adaptivePadding: true) {UserExtraInfo(p: p)}
                if !p.prompt3.response.isEmpty {PromptView(prompt: p.prompt3)}
                ClearRectangle(size: 96)
            }
        }
        .scrollDisabled(!detailsOpen)
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y
        } action: { _, newOffsetY in
            ui.isAtTopOfScroll = newOffsetY <= 5
        }
        .frame(maxWidth: .infinity)
        .frame(height: 600).background(Color.background)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: Color.grayPlaceholder)
        .contentMargins(.bottom, 0, for: .scrollContent)
        .ignoresSafeArea(.container, edges: .bottom)
        .scrollIndicators(.hidden)
        .customScrollFade(height: 80, showFade: !ui.isAtTopOfScroll)
        .overlay(alignment: .topTrailing) {dismissDetailsButton}
    }
}

extension ProfileDetailsView {

    @ViewBuilder private var eventInvite: some View {
        if let event = event, event.status == .accepted {
            DetailsSection(
                color: .appGreen,
                title: "event with \(event.otherUserName)",
                adaptivePadding: true,
                padding: 12
            ) {
                ProfileInviteView(event: event)
            }
            .padding(.bottom, 32)
        }
    }

    private var keyInfoStrokeColour: Color {
        if event?.status == .accepted { return .grayPlaceholder }
        if vm.viewProfileType == .accept { return .appGreen }
        return .accent
    }

    @ViewBuilder
    private var dismissDetailsButton: some View {
        if !ui.isAtTopOfScroll {
            Image(systemName: "chevron.down")
                .font(.body(16, .bold))
                .frame(width: 30, height: 30)
                .glassIfAvailable()
                .padding()
                .padding(.horizontal, 6)
        }
    }

    private var profileInterests: some View {
        DetailsSection(color: .grayPlaceholder, title: "Interests & Character") {
            UserInterests(p: p)
                .padding(.vertical, -12)
        }
    }
}

//To Update in new piece of code

/*
 .frame(maxWidth: .infinity)
 .frame(height: 600).background(Color.background)
 .mask(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
 .stroke(30, lineWidth: 1, color: Color.grayPlaceholder)


 */
