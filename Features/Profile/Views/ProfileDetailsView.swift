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
    @State var isAtTopOfScroll =  true
    
    let event: UserEvent?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if showEventView {
                    if let event {
                        DetailsSection(color: ui.detailsOpen ? .appGreen : Color.grayBackground, title: "event with \(event.otherUserName)", adaptivePadding: true, padding: 12) {
                            ProfileInviteView(ui: ui, event: event)
                        }
                        .padding(.bottom, 32)
                    }
                }
                DetailsSection(color: ui.detailsOpen ? (showEventView ? Color.grayBackground : vm.viewProfileType == .accept ? .appGreen : .accent) : Color.grayBackground, title: "About") {UserKeyInfo(p: p)}
                PromptView(prompt: p.prompt1)
                profileInterests
                PromptView(prompt: p.prompt2)
                DetailsSection(title: "Extra Info", adaptivePadding: true) {UserExtraInfo(p: p)}
                if !p.prompt3.response.isEmpty {PromptView(prompt: p.prompt3)}
            }
            .padding(.bottom, 300)
            .offset(y: 36)
        }
        .frame(height: 600).background(Color.background)
        .mask(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: Color.grayPlaceholder)
        
        //Check if the scroll at the top if it is disable upward scolling
        .onScrollGeometryChange(for: Bool.self, of: { geo in
            geo.contentOffset.y <= geo.contentInsets.top
        }, action: { _, newValue in
            isAtTopOfScroll = newValue
        })
        .scrollDisabled(isAtTopOfScroll || !ui.detailsOpen)
        .scrollIndicators(.hidden)
        .customScrollFade(height: 80, showFade: !ui.isTopOfScroll)
        .overlay(alignment: .topTrailing) {dismissDetailsButton}
    }
}

extension ProfileDetailsView {
    
    
    @ViewBuilder
    private var dismissDetailsButton: some View {
        if !ui.isTopOfScroll && ui.detailsOpen {
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

extension ProfileDetailsView {
    var showEventView: Bool {
        event != nil && event?.status == .accepted
    }
}

//    let onDecline: () -> Void
