//
//  pDetailsView.swift
//  Scoop
//
//  Created by Art Ostin on 23/06/2025.

import SwiftUI
import SwiftUIFlowLayout



struct ProfileDetailsView: View {
    //Injected
    @Bindable var vm: ProfileViewModel
    @Bindable var ui: ProfileUIState
    let p: UserProfile
    let event: UserEvent?

    //Local view state
    @State private var scrollPosition = ScrollPosition(edge: .top)

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                eventInvite
                DetailsSection(color: keyInfoStrokeColour, title: "About") {UserKeyInfo(p: p)}
                    .animation(.spring(duration: 0.42, bounce: 0), value: ui.detailsOpen)
                PromptView(prompt: p.prompt1)
                profileInterests
                PromptView(prompt: p.prompt2)
                DetailsSection(title: "Extra Info", adaptivePadding: true) {DetailsExtraInfo(p: p)}
                if !p.prompt3.response.isEmpty {PromptView(prompt: p.prompt3)}
            }
            .contentMargins(.top, Spacing.lg)
            .contentMargins(.bottom, Spacing.clearance)
            .contentShape(Rectangle())
            .onTapGesture { toggleDetails() }
        }
        .scrollPosition($scrollPosition)
        .onChange(of: ui.isDraggingDetails) { _, dragging in
            //Pin any in-flight top bounce when the card takes over the gesture, so
            //content doesn't sit frozen mid-bounce while the card moves.
            if dragging { scrollPosition.scrollTo(edge: .top) }
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
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: CornerRadius.xl, topTrailingRadius: CornerRadius.xl))
        .stroke(CornerRadius.xl)
        .contentMargins(.bottom, 0, for: .scrollContent)
        .ignoresSafeArea(.container, edges: .bottom)
        .scrollIndicators(.hidden)
        .customScrollFade(height: 80, showFade: !ui.isAtTopOfScroll, isDetails: true)
        .scrollDisabled(ui.isDraggingDetails || !ui.detailsOpen)
        .overlay(alignment: .topTrailing) {
            dismissDetailsButton
                .blurPop(visible: !ui.isAtTopOfScroll && ui.detailsFullyOpen)
                .padding()
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
        if !ui.detailsOpen {
            Color.border.opacity(0.5)
        } else if vm.viewProfileType == .accept {
            Color.successGreen
        } else {
            Color.accent
        }
    }

    private var dismissDetailsButton: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), size: .small) {
            ui.animateDetails(to: false)
        } label: {
            Image(systemName: "chevron.down")
                .font(.body(15, .bold))
        }
    }
        

    private var profileInterests: some View {
        DetailsSection(color: .border, title: "Interests & Character") {
            UserInterests(p: p)
                .padding(.vertical, -12)
        }
    }

    func toggleDetails() {
        ui.animateDetails(to: !ui.detailsOpen)
    }
}
