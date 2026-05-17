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
            .contentShape(Rectangle())
            .onTapGesture { toggleDetails() }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y
        } action: { _, newOffsetY in
            ui.isAtTopOfScroll = newOffsetY <= 5 //if it is it is at top of scrollView
        }
        .frame(maxWidth: .infinity)
        .frame(height: 600).background(Color.background)
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
        withAnimation(.smooth) {
            if !ui.detailsOpen {
                return Color.grayPlaceholder.opacity(0.4)
            } else if vm.viewProfileType == .accept {
                  return Color.appGreen
            } else {
                return Color.accent
            }
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
        let willOpen = !ui.detailsOpen
        let target = willOpen ? ui.detailsOpenOffset : ui.detailsClosedOffset
        if !willOpen { ui.detailsFullyOpen = false }
        withAnimation(.interpolatingSpring(stiffness: 250, damping: 25)) {
            ui.detailsOpen = willOpen
            ui.detailsOffset = target
        }
        if willOpen {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.23))
                if ui.detailsOpen { ui.detailsFullyOpen = true }
            }
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
