//
//  pDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//var isThreePrompts: Bool { p.prompt3.response.isEmpty == true }


import SwiftUI
import SwiftUIFlowLayout

struct ProfileDetailsView: View {
    
    @Bindable var vm: ProfileViewModel
    let p: UserProfile
    let event: UserEvent?
    let detailsOpen: Bool
    let detailsOffset: CGFloat
    
    @State private var totalHeight: CGFloat = 0
    
    @State private var scrollSelection: Int? = 0
    @State var scrollBottom: CGFloat = 0
    var showProfileEvent: Bool { event != nil || p.idealMeetUp != nil}
    
    @State private var flowLayoutBottom: CGFloat = 0
    @State private var interestSectionBottom: CGFloat = 0
    @State private var interestScale: CGFloat = 1
    
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
            .offset(y: 16) //Acts as padding
            .scrollTargetLayout()
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollSelection, anchor: .center)
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                PageIndicator(count: 3, selection: scrollSelection ?? 0)
                    .frame(maxWidth: .infinity, alignment: .center)
//                    .offset(y: 6)
                
                DeclineButton() {}
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 24)
                    .offset(y: -24)
            }
            .offset(y: 24)
        }
        .padding(.bottom, scrollSelection == 2 && scrollThirdTab ? 0 :  250)
        .background(Color.background)
        .mask(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: .grayPlaceholder)
        .measure(key: TopOfDetailsView.self) {$0.frame(in: .named("profile")).minY}
//        .scaleEffect(detailsOpen ? 1 : 0.95) //Adjust so scale Effect works and distance between objects is same
    }
}

extension ProfileDetailsView {
    private var detailsScreen1: some View {
        VStack(spacing: 16) {
            DetailsSection(color: detailsOpen ? .accent : Color.grayPlaceholder, title: "About") {UserKeyInfo(p: p)}
                if showProfileEvent {
                    DetailsSection(title: "\(p.name)'s preferred meet") {ProfileEvent(p: p, event: event)}
                } else {
                    DetailsSection(){ PromptView(prompt: p.prompt1) }
            }
        }
    }
    
    private var detailsScreen2: some View {
        VStack(spacing: 16) {
            DetailsSection(color: .grayPlaceholder, title: "Interests & Character") {
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
        .coordinateSpace(.named("InterestsSection"))
    }
    
    private var detailsScreen3: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                DetailsSection(title: "Extra Info") {
                    UserExtraInfo(p: p)
                }
                if scrollThirdTab {
                    DetailsSection(color: .red) {
                        PromptView(prompt: p.prompt2)
                    }
                    DetailsSection(color: .blue) {
                        PromptView(prompt: p.prompt3)
                    }
                } else if showProfileEvent {
                    DetailsSection() {
                        PromptView(prompt: p.prompt2)
                    }
                } else if !p.prompt3.response.isEmpty {
                    DetailsSection(color: .blue) {
                        PromptView(prompt: p.prompt3)
                    }
                }
            }
            .padding(.bottom, 148)
            .offset(y: 12)
        }
        .frame(maxHeight: .infinity)
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
}
