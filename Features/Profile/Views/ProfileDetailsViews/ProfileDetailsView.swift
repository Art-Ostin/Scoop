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
                    .animation(.smooth, value: ui.detailsOpen)
                PromptView(prompt: p.prompt1)
                profileInterests
                PromptView(prompt: p.prompt2)
                DetailsSection(title: "Extra Info", adaptivePadding: true) {UserExtraInfo(p: p)}
                if !p.prompt3.response.isEmpty {PromptView(prompt: p.prompt3)}
                ClearRectangle(size: 96)
            }
            .contentShape(Rectangle())
            .onTapGesture { if !ui.detailsOpen { toggleDetails() } }
        }
        .scrollPosition($scrollPosition)
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y
        } action: { _, newOffsetY in
            ui.isAtTopOfScroll = newOffsetY <= 5 //if it is it is at top of scrollView
        }
        .onChange(of: ui.detailsOpen) { _, isOpen in
            if !isOpen {
                withAnimation(.smooth) { scrollPosition.scrollTo(edge: .top) }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: ui.detailsCardHeight).background(Color.background)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: Color.grayPlaceholder)
        .contentMargins(.bottom, 0, for: .scrollContent)
        .ignoresSafeArea(.container, edges: .bottom)
        .scrollIndicators(.hidden)
        .customScrollFade(height: 80, showFade: !ui.isAtTopOfScroll)
        .scrollDisabled(ui.isDraggingDetails)
        .overlay(alignment: .topTrailing) {
            dismissDetailsButton //Control animation depending on how it is open.
                .transaction(value: ui.detailsFullyOpen) { $0.animation = ui.detailsFullyOpen ? .smooth : nil}
                .transaction(value: ui.isAtTopOfScroll) { $0.animation = .smooth}
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

    @ViewBuilder
    private var dismissDetailsButton: some View {
        if !ui.isAtTopOfScroll && ui.detailsFullyOpen {
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

    func toggleDetails() {
        ui.animateDetails(to: !ui.detailsOpen)
    }
}
