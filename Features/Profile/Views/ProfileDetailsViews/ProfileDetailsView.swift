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

    @State private var scrollPosition = ScrollPosition(edge: .top)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ClearRectangle(size: 24)
                eventInvite
                DetailsSection(color: keyInfoStrokeColour, title: "About") {UserKeyInfo(p: p)}
                    .animation(.spring(duration: 0.42, bounce: 0), value: ui.detailsOpen)
                PromptView(prompt: p.prompt1)
                profileInterests
                PromptView(prompt: p.prompt2)
                DetailsSection(title: "Extra Info", adaptivePadding: true) {UserExtraInfo(p: p)}
                if !p.prompt3.response.isEmpty {PromptView(prompt: p.prompt3)}
                ClearRectangle(size: 200)
            }
            .contentShape(Rectangle())
            .onTapGesture { toggleDetails() }
        }
        .scrollPosition($scrollPosition)
        .onScrollPhaseChange { oldPhase, newPhase in
            ui.touchingScrollView = newPhase == .tracking || newPhase == .interacting
        }
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y
        } action: { _, newOffsetY in
            // Hysteresis: enter "at top" at 0, leave only past 8, so scroll bounce doesn't flicker the flag
            if ui.isAtTopOfScroll {
                if newOffsetY > 8 { ui.isAtTopOfScroll = false }
            } else {
                if newOffsetY <= 0 { ui.isAtTopOfScroll = true }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: ui.detailsCardHeight).background(Color.appCanvas)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: Color.grayPlaceholder)
        .contentMargins(.bottom, 0, for: .scrollContent)
        .ignoresSafeArea(.container, edges: .bottom)
        .scrollIndicators(.hidden)
        .customScrollFade(height: 80, showFade: !ui.isAtTopOfScroll, isDetails: true)
        .scrollDisabled(ui.isDraggingDetails || !ui.detailsOpen)
        .overlay(alignment: .topTrailing) {
            dismissDetailsButton
                .opacity(!ui.isAtTopOfScroll && ui.detailsFullyOpen ? 1 : 0)
                .animation(.smooth(duration: 0.2), value: ui.detailsFullyOpen)
                .animation(.smooth(duration: 0.2), value: ui.isAtTopOfScroll)
        }
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
        if !ui.detailsOpen {
            Color.grayPlaceholder.opacity(0.4)
        } else if vm.viewProfileType == .accept {
            Color.appGreen
        } else {
            Color.accent
        }
    }

    private var dismissDetailsButton: some View {
        Image(systemName: "chevron.down")
            .font(.body(16, .bold))
            .frame(width: 30, height: 30)
            .hoverButton()
            .padding()
            .padding(.horizontal, 6)
    }

    private var profileInterests: some View {
        DetailsSection(color: .grayPlaceholder, title: "Interests & Character") {
            UserInterests(p: p)
                .padding(.vertical, -12)
        }
    }

    func toggleDetails() {
        ui.animateDetails(to: !ui.detailsOpen)
    }
}
