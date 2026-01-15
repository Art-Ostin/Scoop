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
    @Binding var scrollSelection: Int?
    
    let p: UserProfile
    let event: UserEvent?
    let detailsOpen: Bool
    let detailsOffset: CGFloat
    
    @State private var totalHeight: CGFloat = 0
    
    @State var scrollBottom: CGFloat = 0
    var showProfileEvent: Bool { event != nil || p.idealMeetUp != nil}
    
    @State private var flowLayoutBottom: CGFloat = 0
    @State private var interestSectionBottom: CGFloat = 0
    @State private var interestScale: CGFloat = 1
    
    @Binding var showInvite: Bool
    @Binding var showDecline: Bool
    @Binding var selectedProfile: ProfileModel?
    
    var scrollThirdTab: Bool { showProfileEvent && !p.prompt3.response.isEmpty }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                detailsScreen1
                    .containerRelativeFrame(.horizontal)
                    .id(0)
                detailsScreen2
                    .containerRelativeFrame(.horizontal)
                    .id(1)
                detailsScreen3
                    .containerRelativeFrame(.horizontal)
                    .id(2)
            }
            .scrollTargetLayout()
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollSelection, anchor: .center)
        .overlay(alignment: .top) {
            HStack {
                DeclineButton() {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showDecline = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                            var transaction = Transaction()
                            transaction.animation = .easeInOut(duration: 0.2)
                            withTransaction(transaction) {
                                selectedProfile = nil
                            }
                        }
                    }
                }
                .offset(y: -24)
                Spacer()
                PageIndicator(count: 3, selection: scrollSelection ?? 0)
                Spacer()
                InviteButton(vm: vm, showInvite: $showInvite)
                    .offset(y: -24)
            }
            .padding(.horizontal, 16)
            .offset(y: 372)
        }
        .padding(.bottom, scrollSelection == 2 && scrollThirdTab ? 0 :  250)
        .background(Color.background)
        .mask(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: .grayPlaceholder)
        .scaleEffect(detailsOpen ? 1 : 0.95, anchor: .top) //Adjust so scale Effect works and distance between objects is same
    }
}

extension ProfileDetailsView {
    private var detailsScreen1: some View {
        VStack(spacing: 16) {
            DetailsSection(color: detailsOpen ? .accent : Color.grayBackground, title: "About") {UserKeyInfo(p: p)}
                if showProfileEvent {
                    DetailsSection(title: "\(p.name)'s preferred meet") {ProfileEvent(p: p, event: event)}
                } else {
                    DetailsSection() { PromptView(prompt: p.prompt1) }
            }
        }
        .offset(y: 16)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    private var detailsScreen2: some View {
        VStack(spacing: 16) {
            DetailsSection(color: detailsOpen ? .grayPlaceholder : .grayBackground, title: "Interests & Character") {
                UserInterests(p: p, interestScale: interestScale)
                    .padding(.vertical, interestScale == 0 ? 0 : -12)
            }
            .measure(key: InterestsBottomKey.self) {$0.frame(in: .named("InterestsSection")).maxY}
            .onPreferenceChange(InterestsBottomKey.self) { interestSectionBottom = $0 }
            .onPreferenceChange(FlowLayoutBottom.self) { flowLayoutBottom = $0 }
            .onChange(of: flowLayoutBottom) {
                updateInterestScale()
            }
            
            DetailsSection() {
                PromptView(prompt: showProfileEvent ? p.prompt1 : p.prompt2)
            }
        }
        .offset(y: 16)
        .frame(maxHeight: .infinity, alignment: .top)
        .coordinateSpace(.named("InterestsSection"))
    }
    
    @ViewBuilder
    private var detailsScreen3: some View {
        if scrollThirdTab {
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    DetailsSection(color: detailsOpen ? .grayPlaceholder : .grayBackground, title: "Extra Info") {UserExtraInfo(p: p) }
                    DetailsSection() {PromptView(prompt: p.prompt2)}
                    DetailsSection() {PromptView(prompt: p.prompt3)}
                }
                .offset(y: 16)
                .padding(.bottom, 200)
            }
            .scrollDisabled(disableDetailsScroll)
            .onScrollGeometryChange(for: Bool.self) { geo in
                let y = geo.contentOffset.y + geo.contentInsets.top
                return y <= 0.5
            } action: { _, isAtTop in
                self.isTopOfScroll = isAtTop
            }
            .frame(height: 600, alignment: .top)
        } else {
            VStack(spacing: 16) {
                DetailsSection(color: detailsOpen ? .grayPlaceholder : .grayBackground, title: "Extra Info") {UserExtraInfo(p: p) }
                if showProfileEvent {
                    DetailsSection() {PromptView(prompt: p.prompt2)}
                } else if !p.prompt3.response.isEmpty {
                    DetailsSection() {PromptView(prompt: p.prompt3)}
                }
            }
            .offset(y: 16)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

struct TopOfDetailsView: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension ProfileDetailsView {
    func updateInterestScale() {
        guard flowLayoutBottom > 0, interestSectionBottom > 0 else { return }
        guard flowLayoutBottom > interestSectionBottom else { return }
        let newScale = max(interestSectionBottom / flowLayoutBottom, 0.1)
        if newScale < interestScale {
            interestScale = newScale
        }
    }

    var disableDetailsScroll: Bool {
           !detailsOpen || detailsOpen && scrollSelection == 2 && isTopOfScroll && detailsOffset > 0
    }
}





/*
 //
 //        .overlay(alignment: .top) {
 //            InviteButton(vm: vm, showInvite: $showInvite)
 //                .frame(maxWidth: .infinity, alignment: .trailing)
 //                .padding(.horizontal, 16)
 //                .offset(y: 384 - 24)
 //        }

 */

/*
 .measure(key: TopOfDetailsView.self) {$0.frame(in: .named("profile")).minY}
 */
