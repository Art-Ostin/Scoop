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
    
    ///The pinned header's measured height — the pages inset their content by it.
    @State private var headerHeight: CGFloat = 0
    
    ///The band the fade has to cover: the nav bar's inset plus that content inset.
    @State private var fadeHeight: CGFloat = 0
    
    //Geometry: the 28pt that used to be the VStack's spacing between the icons and the pager
    private var contentTop: CGFloat { headerHeight + 28 }

    var body: some View {
        ZoomNavigationStack {
            NavigationStack {
                scrollSection
                    .overlay(alignment: .top) { headerBand }
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
    
    ///An overlay, not a layout sibling: the pages start at the top of the screen so their content
    ///can scroll up behind this, and this has to draw above the fade that dissolves it.
    private var headerBand: some View {
        VStack(spacing: 28) {
            headingSection
            
            selectionSection
        }
        .padding(.top, Spacing.xs)
        .getHeight($headerHeight)
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
        .contentMargins(.top, contentTop, for: .scrollContent)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentInsets.top } action: { _, top in
            fadeHeight = top
        }
        .customScrollFade(height: fadeHeight, color: .white, showFade: true, edge: .top, isDetails: false, isStrong: true)
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
