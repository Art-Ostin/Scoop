//
//  pDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.

import SwiftUI
import SwiftUIFlowLayout

struct ProfileDetailsView: View {
    @Bindable var vm: ProfileViewModel
    @Binding var isTopOfScroll: Bool
    @Binding var showInvite: Bool
    
    let detailsOpen: Bool
    let detailsOffset: CGFloat
    let p: UserProfile
    
    @State private var flowLayoutBottom: CGFloat = 0
    @State private var interestSectionBottom: CGFloat = 0
    @State private var interestScale: CGFloat = 1
    
    let onDecline: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                DetailsSection(color: detailsOpen ? .accent : Color.grayPlaceholder, title: "About") {UserKeyInfo(p: p)}
                PromptView(prompt: p.prompt1)
                profileInterests
                PromptView(prompt: p.prompt2)
                DetailsSection(title: "Extra Info") {UserExtraInfo(p: p)}
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
            self.isTopOfScroll = isAtTop
        }
        .scrollDisabled(disableDetailsScroll)
        .scrollIndicators(.hidden)
        .overlay(alignment: .top) { if vm.viewProfileType != .view {profileActionBar}}
        .overlay(alignment: .top) {
            if !isTopOfScroll {
                gradientCover
                    .offset(y: 0.5)
            }
        }
        .overlay(alignment: .topTrailing) {dismissDetailsButton}
    }
}

extension ProfileDetailsView {
    @ViewBuilder
    private var dismissDetailsButton: some View {
        if !isTopOfScroll && detailsOpen {
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
    
    private var profileActionBar: some View {
        HStack {
            DeclineButton() {onDecline()}
            Spacer()
            InviteButton(vm: vm, showInvite: $showInvite)
        }
        .padding(.horizontal, 16)
        .offset(y: 354)
    }
    
    private var gradientCover: some View {
        LinearGradient(colors: [.white, .white.opacity(0.9), .white.opacity(0.6), .white.opacity(0.25), .white.opacity(0.0)], startPoint: .top, endPoint: .bottom)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .cornerRadius(30)
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
        !detailsOpen || (isTopOfScroll && detailsOffset > 0)
    }
}


/*
 //                .background(
 //                    Circle()
 //                        .fill(Color.background)
 //                        .shadow(color: .black.opacity(0.05), radius: 1.5, x: 0, y: 3)
 //                        .stroke(200, lineWidth: 0.5, color: Color.grayBackground)
 //                )
 */
