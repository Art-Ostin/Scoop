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
    
    @State private var scrollSelection: Int? = 0
    @State var scrollBottom: CGFloat = 0
    var showProfileEvent: Bool { event != nil || p.idealMeetUp != nil}
    let scrollCoord = "Scroll"

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                detailsScreen1
                    .containerRelativeFrame(.horizontal)
                    .id(0)
                    .padding(.bottom, 36)
                detailsScreen2
                    .containerRelativeFrame(.horizontal)
                    .id(1)
                detailsScreen3
                    .containerRelativeFrame(.horizontal)
                    .id(2)
            }
            .scrollTargetLayout()
        }
        .measure(key: TopOfDetailsView.self) {$0.frame(in: .named("profile")).minY}
        .scrollIndicators(.hidden)
        .coordinateSpace(name: scrollCoord)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollSelection, anchor: .center)
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                PageIndicator(count: 3, selection: scrollSelection ?? 0)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(y: 16)
                
                DeclineButton() {}
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16)
            }
            .offset(y: 24)
        }
        .padding(.top, 16)
        .padding(.bottom, 250)
        .background(Color.background)
        .mask(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: .grayPlaceholder)
        .scaleEffect(detailsOpen ? 1 : 0.95)
    }
}

extension ProfileDetailsView {
    private var detailsScreen1: some View {
        VStack(spacing: 16) {
            DetailsSection(color: .accent) {
                UserKeyInfo(p: p)
            }
            DetailsSection() {
                if showProfileEvent {
                    ProfileEvent(p: p, event: event)
                } else {
                    PromptView(prompt: p.prompt1)
                }
            }
        }
    }
    
    private var detailsScreen2: some View {
        VStack(spacing: 16) {
            DetailsSection(color: .accent) {
                UserInterests(p: p)
            }
            DetailsSection() {
                PromptView(prompt: showProfileEvent ? p.prompt1 : p.prompt2)
            }
        }
    }
    
    private var detailsScreen3: some View {
                
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                DetailsSection(color: .accent) {
                    UserExtraInfo(p: p)
                }
                if showProfileEvent {
                    DetailsSection(color: .accent) {
                        PromptView(prompt: p.prompt2)
                    }
                } else if showProfileEvent && !p.prompt3.prompt.isEmpty {
                    DetailsSection(color: .red) {
                        PromptView(prompt: p.prompt2)
                    }
                    DetailsSection(color: .blue) {
                        PromptView(prompt: p.prompt3)
                    }
                } else if !p.prompt3.response.isEmpty {
                    DetailsSection(color: .green) {
                        PromptView(prompt: p.prompt3)
                    }
                }
            }
        }
    }
}

struct TopOfDetailsView: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}




/*
 .overlay(alignment: .top) {
     InviteButton(vm: vm, showInvite: $showInvite)
         .offset(y: 12)
 }
 */
