//
//  HistoryContainer.swift
//  Scoop
//
//  Created by Art Ostin on 20/08/2026.
//

import SwiftUI
import Glur

struct HistoryContainer: View {

    @Environment(\.dismiss) private var dismiss
    @State var vm: HistoryViewModel
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
    
    @State var showPastInvites: Bool = false
    
    @State var scrollPosition = ScrollPosition()
    
    //Geometry: the gap between the icons and the cards. It used to be the VStack's spacing; now
    //it lives inside the pages as a content inset, so cards scroll up into it and fade out there.
    private let fadeBand: CGFloat = 28

    var body: some View {
        ZoomNavigationStack {
            NavigationStack {
                VStack(spacing: 0) {
                    headerBand
                    
                    scrollSection
                }
                .navigationTitle("History")
                .colorBackground()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        dismissButton
                    }
                }
            }
        }
        .environment(ZoomPresentationHost?.none)
        .ignoresSafeArea()
    }
}

//Pinned header: the title, heading and section icons stay put while the pages slide beneath
extension HistoryContainer {
    
    //Sits hard against the pager, which clips the cards at the icons' baseline
    private var headerBand: some View {
        VStack(spacing: 28) {
            headingSection
            
            selectionSection
        }
        .padding(.top, Spacing.xs)
    }
    
    private var headingSection: some View {
        (
            Text("Declines from the last 2 days")
                .font(.body(14, .bold))
            +
            Text(" if you change your mind")
                .font(.body(14, .medium))
        )
        .foregroundStyle(Color.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.gutter)
    }
    
    private var selectionSection: some View {
        HStack {
            Image(.inviteBlack)
            
            Spacer()
            
            Image(.smallDeclineBlack)
                .scaleEffect(0.9)
        }
        .padding(.horizontal, 90)
    }
    
    ///Everything below the icons is the pager. Each page is its own full-height vertical
    private var scrollSection: some View {
        HorizontalScrollView(progress: .constant(0), position: $scrollPosition) {
            pastDeclineSection
                .containerRelativeFrame(.horizontal)
                .id(0)
            
            pastInviteSection
                .containerRelativeFrame(.horizontal)
                .id(1)
        }
    }
}

//Recently declined page
extension HistoryContainer {
    
    private func page<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            content()
        }
        //Inset and fade are the same value, so nothing is ever washed at rest
        .contentMargins(.top, fadeBand, for: .scrollContent)
        .scrollIndicators(.hidden)
        .customScrollFade(height: fadeBand, isStrong: true)
    }
    
    private var pastDeclineSection: some View {
        page {
            if vm.declines.isEmpty {
                pastDeclinePlaceholder
            } else {
                pastDeclineCards
            }
        }
    }
    
    private var pastDeclinePlaceholder: some View {
        Text("No Profiles")
    }
    
    private var pastDeclineCards: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(vm.declines) { decline in
                HistoryCard(decline: decline, vm: vm)
            }
        }
        .padding(.horizontal, Spacing.gutter)
        .padding(.bottom, Spacing.clearance)
    }
    
    private var dismissButton: some View {
        Image(systemName: "xmark")
            .foregroundStyle(.black)
            .font(.icon(14))
            .onTapGesture {
                dismiss()
            }
    }
}

//Past invites page
extension HistoryContainer {
    
    private var pastInviteSection: some View {
        page {
            ForEach(vm.sentInvites, id: \.self) { invite in
                Text(invite.profile.name)
            }
        }
    }
}
