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
    
    let detailsOpen: Bool
    let detailsOffset: CGFloat
    
    let p: UserProfile
    @State var scrollBottom: CGFloat = 0
    
    @State private var flowLayoutBottom: CGFloat = 0
    @State private var interestSectionBottom: CGFloat = 0
    @State private var interestScale: CGFloat = 1
    
    @Binding var showInvite: Bool
    @Binding var selectedProfile: ProfileModel?
    
    let onDecline: () -> Void
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {
                DetailsSection(color: detailsOpen ? .accent : Color.grayPlaceholder, title: "About") {UserKeyInfo(p: p)}
                PromptView(prompt: p.prompt1)
                profileInterests
                PromptView(prompt: p.prompt2)
                DetailsSection(title: "Extra Info") {UserExtraInfo(p: p)}
                if !p.prompt3.response.isEmpty {PromptView(prompt: p.prompt3)}
            }
            .padding(.bottom, 300)
        }
        .frame(height: 600)
        .coordinateSpace(.named("InterestsSection"))
        .onScrollGeometryChange(for: Bool.self, of: checkIfTopOfScroll) { _, isAtTop in
            self.isTopOfScroll = isAtTop
        }
        .scrollDisabled(disableDetailsScroll)
        .background(Color.background)
        .mask(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: .grayPlaceholder)
        .scrollIndicators(.hidden)
        .overlay(alignment: .topTrailing) {dismissDetailsButton}
        .overlay(alignment: .top) {profileActionBar}
    }
}

extension ProfileDetailsView {
    @ViewBuilder
    private var dismissDetailsButton: some View {
        if !isTopOfScroll && detailsOpen {
            Image(systemName: "chevron.down")
                .font(.body(16, .bold))
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.background.opacity(0.93))
                )
                .padding()
                .padding(.horizontal, 6)
        }
    }
    
    private var profileInterests: some View {
        DetailsSection(color: .grayPlaceholder, title: "Interests & Character") {
            UserInterests(p: p, interestScale: interestScale)
                .padding(.vertical, interestScale == 0 ? 0 : -12)
        }
        .measure(key: InterestsBottomKey.self) {$0.frame(in: .named("InterestsSection")).maxY}
        .onPreferenceChange(InterestsBottomKey.self) { interestSectionBottom = $0 }
        .onPreferenceChange(FlowLayoutBottom.self) { flowLayoutBottom = $0 }
        .onChange(of: flowLayoutBottom) { updateInterestScale()}
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
        
    }
    
    
    var disableDetailsScroll: Bool {
        !detailsOpen || isTopOfScroll && detailsOffset > 0
    }
}
