//
//  pDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//var isThreePrompts: Bool { p.prompt3.response.isEmpty == true }


import SwiftUI
import SwiftUIFlowLayout

struct ProfileDetailsView: View {
    
    @State private var scrollSelection: Int? = 0
    @State var scrollBottom: CGFloat = 0
    
    let p: UserProfile
    let event: UserEvent?
    var showProfileEvent: Bool { event != nil || p.idealMeetUp != nil}
    let scrollCoord = "Scroll"

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
        }
        .coordinateSpace(name: scrollCoord)
        .overlay(alignment: .bottom) {
            PageIndicator(count: 3, selection: scrollSelection ?? 0)
            DeclineButton() {}
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 24)
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollSelection, anchor: .center)
        .padding(.top, 16)
        .padding(.bottom, 36)
        .background(Color.background)
        .mask(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: .grayPlaceholder)
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
