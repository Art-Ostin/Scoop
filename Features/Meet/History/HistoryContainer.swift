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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.canvasSunken.ignoresSafeArea())
                .task(id: vm.declines) { await loadProfileImages() }
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

//Logic to do with the header
extension HistoryContainer {
    //Sits hard against the pager, which clips the cards at the icons' baseline
    private var headerBand: some View {
        VStack(spacing: 28) {
            headingSection
            
            SelectionSection(selectedPage: $selectedPage, ui: ui)
        }
        .padding(.top, Spacing.xs)
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
    
    private var dismissButton: some View {
        Image(systemName: "xmark")
            .foregroundStyle(.black)
            .font(.icon(14))
            .onTapGesture {
                dismiss()
            }
    }
    
    private func loadProfileImages () async {
        for decline in vm.declines where vm.profileImages[decline.id] == nil {
            await vm.loadProfileImages(decline.profile.profile)
        }
    }
}

extension HistoryContainer {
    
    private var scrollSection: some View {
        HistoryPager(selectedPage: $selectedPage, progress: $ui.pagerProgress) {
            pendingInvitesView
                .containerRelativeFrame(.horizontal)
                .id(0)
            
            pastDeclineSection
                .containerRelativeFrame(.horizontal)
                .id(1)
        }
    }
    
    private func page<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            content()
        }
        .contentMargins(.top, fadeBand, for: .scrollContent)
        .scrollIndicators(.hidden)
        .customScrollFade(height: fadeBand, color: .canvasWarm, curve: .even)
    }
    
    private var pastDeclineSection: some View {
        page {
            RecentDeclines(declines: vm.declines,
                           profileImages: vm.profileImages,
                           imageLoader: vm.imageLoader,
                           defaults: vm.defaults)
        }
    }
    
    private var pendingInvitesView: some View {
        page {
            PendingInvitesView(inviteDays: vm.invitesByDay, ui: ui)
        }
    }
}

struct HistoryPager<Content: View>: View {

    //Injected
    @Binding var selectedPage: Int?
    var progress: Binding<Double> = .constant(0)
    @ViewBuilder let content: Content

    //Local view state
    @State private var pagedId: Int? = 0
    @State private var scrollDriven = false

    var body: some View {
        HorizontalScrollView(progress: progress) {
            content
        }
        .scrollPosition(id: $pagedId)
        .animation(scrollDriven ? nil : .move, value: pagedId)
        .onChange(of: selectedPage) { _, newPage in
            guard let newPage, newPage != pagedId else { return }
            pagedId = newPage
        }
        .onScrollPhaseChange { _, phase in
            scrollDriven = phase == .interacting || phase == .decelerating
            guard phase == .idle, pagedId != selectedPage else { return }
            selectedPage = pagedId
        }
    }
}
