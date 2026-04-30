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
    let detailsOffset: CGFloat
    let event: UserEvent?
        
    @State private var flowLayoutBottom: CGFloat = 0
    @State private var interestSectionBottom: CGFloat = 0
    @State private var interestScale: CGFloat = 1

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
        .stroke(30, lineWidth: 1, color: .grayPlaceholder)
        .coordinateSpace(.named("InterestsSection"))
        .onScrollGeometryChange(for: Bool.self, of: checkIfTopOfScroll) { _, isAtTop in
            self.ui.isTopOfScroll = isAtTop
        }
        .scrollDisabled(disableDetailsScroll)
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
            UserInterests(p: p, interestScale: interestScale)
                .padding(.vertical, -12)
        }
        .measure(key: InterestsBottomKey.self) {$0.frame(in: .named("InterestsSection")).maxY}
        .onPreferenceChange(InterestsBottomKey.self) { interestSectionBottom = $0 }
        .onPreferenceChange(FlowLayoutBottom.self) { flowLayoutBottom = $0 ; updateInterestScale()}
    }
    
}

extension ProfileDetailsView {
    func updateInterestScale() {
        guard flowLayoutBottom > 0, interestSectionBottom > 0 else { return }
        guard flowLayoutBottom > interestSectionBottom else { return }
        let newScale = max(interestSectionBottom / flowLayoutBottom, 0.1)
        if newScale < interestScale { interestScale = newScale}
    }
    
    func checkIfTopOfScroll(_ geo: ScrollGeometry) -> Bool {
        geo.contentOffset.y + geo.contentInsets.top <= 0.5
    }
    
    var disableDetailsScroll: Bool {
        !ui.detailsOpen || (ui.isTopOfScroll && detailsOffset > 0)
    }
    
    var showEventView: Bool {
        event != nil && event?.status == .accepted
    }
}

//    let onDecline: () -> Void
