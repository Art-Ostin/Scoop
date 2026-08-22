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
    
    @State private var selectedPage: Int? = 0
    
    @State private var ui = HistoryUIState()
    
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
        //Above the pager: the underline hangs below this band into the pager's frame, and the
        //pages' top fade strips otherwise paint semi-opaque canvas over it (a later sibling
        //draws on top of an earlier one's overflowing overlay).
        .zIndex(1)
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
    
    ///The indicator's coordinate space: icon anchors and the underline resolve in the same frame.
    private static let selectionSpace = "historySelection"
    
    private var selectionSection: some View {
        HStack {
            Image(.smallDeclineBlack)
                .scaleEffect(0.9)
                .shrinkPress { selectedPage = 0 }
                .getRect($ui.declineIconFrame, coordSpace: Self.selectionSpace)
            
            Spacer()
            Image(.inviteBlack)
                .shrinkPress { selectedPage = 1 }
                .getRect($ui.inviteIconFrame, coordSpace: Self.selectionSpace)
        }
        .padding(.horizontal, 90)
        .coordinateSpace(name: Self.selectionSpace)
        .overlay(alignment: .bottomLeading) {
            SelectionUnderline(ui: ui)
                .offset(y: Spacing.sm) //Rests just below the icon row
                .allowsHitTesting(false) //Decorative — its overhang must not steal the pager's pan
        }
    }
    
    private var scrollSection: some View {
        HistoryPager(selectedPage: $selectedPage, progress: $ui.pagerProgress) {
            pastDeclineSection
                .containerRelativeFrame(.horizontal)
                .id(0)
            
            pastInviteSection
                .containerRelativeFrame(.horizontal)
                .id(1)
        }
    }
}

private struct HistoryPager<Content: View>: View {

    //Injected
    @Binding var selectedPage: Int?
    var progress: Binding<Double> = .constant(0)
    @ViewBuilder let content: Content

    //Local view state
    @State private var pagedId: Int? = 0
    ///True while the finger or its fling owns the offset — the write-backs that must not animate.
    @State private var scrollDriven = false

    var body: some View {
        HorizontalScrollView(progress: progress) {
            content
        }
        .scrollPosition(id: $pagedId)
        .animation(scrollDriven ? nil : .move, value: pagedId)
        .onChange(of: selectedPage) { _, newPage in
            guard let newPage, newPage != pagedId else { return }
            pagedId = newPage //The icon tap
        }
        .onScrollPhaseChange { _, phase in
            scrollDriven = phase == .interacting || phase == .decelerating
            guard phase == .idle, pagedId != selectedPage else { return }
            selectedPage = pagedId //Only the resting page travels back up
        }
    }
}

///The underline that tracks the pager — a pure function of the scroll offset, so it follows a
private struct SelectionUnderline: View {

    //Injected
    let ui: HistoryUIState

    private static let width: CGFloat = 38

    var body: some View {
        let progress = min(max(ui.pagerProgress, 0), 1) //Rubber-banding runs past both ends
        let from = ui.declineIconFrame.midX
        let to = ui.inviteIconFrame.midX

        RoundedRectangle(cornerRadius: 2)
            .frame(width: Self.width, height: 2.5)
            .foregroundStyle(Color.accent)
            .offset(x: from + (to - from) * progress - Self.width / 2) //Centered on the anchor
            .opacity(ui.inviteIconFrame == .zero ? 0 : 1) //Hidden until the anchors are measured
    }
}

//Recently declined page
extension HistoryContainer {
    
    private func page<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            content()
        }
        .contentMargins(.top, fadeBand, for: .scrollContent)
        .scrollIndicators(.hidden)
        .customScrollFade(height: fadeBand, curve: .even)
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
            ForEach(vm.sentInvites, id: \.self) {invite in
                Text(invite.profile.name)
            }
        }
    }
}
