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

    @State private var profileOpen = false

    @State private var pendingScroll = ScrollPosition()

    @State private var eventZoomHost = EventZoomHost() //The cover's own plane: the app root's host leaks in here but renders behind the cover
    
    private let fadeBand: CGFloat = 32

    private let expiredReveal: CGFloat = 400
    
    var body: some View {
        ZoomNavigationStack(isDetailPresented: $profileOpen) {
            VStack(spacing: 0) {
                headerBand
                
                scrollSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.canvasSunken.ignoresSafeArea())
            .task(id: vm.declines) { await loadDeclineImages() }
            .task(id: vm.sentInvites) { await loadInviteImages() }
            .overlay { dismissButtonLayer }
            .eventZoomHost(eventZoomHost) //Above the xmark: a lens' card and its backdrop cover the screen's chrome
        }
        .environment(ZoomPresentationHost?.none)
        .interactiveDismissDisabled(eventZoomHost.isPresenting || profileOpen)
        .ignoresSafeArea()
    }
}

//Logic to do with the header
extension HistoryContainer {
    //Sits hard against the pager, which clips the cards at the underline's baseline
    private var headerBand: some View {
        VStack(alignment: .leading, spacing: 24) {
            HistoryTitle(ui: ui)
            
            HistorySubHeading(ui: ui)
                .padding(.top, -12)
            
            SelectionSection(selectedPage: $selectedPage, ui: ui)
        }
        .padding(.top, 36)
        .padding(.horizontal, Spacing.gutter)
        .zIndex(1)
    }
    
    
    private var dismissButtonLayer: some View {
        GeometryReader { proxy in
            dismissButton
                .padding(.bottom, Spacing.xxl
                    + max(0, proxy.size.height + proxy.safeAreaInsets.top
                        + proxy.safeAreaInsets.bottom - UIScreen.main.bounds.height)) //Geometry: the library's canvas overgrowth, read from inside the safe-area frame
                .padding(.horizontal, Spacing.margin)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    private var chromeVisible: Bool { !eventZoomHost.chromeHidden } //Back a beat into a card's close, while it is still flying home

    private var dismissButton: some View {
        ScoopButton(style: .glass, shape: Circle(), size: .xLarge, press: .grow) {
            dismiss()
        } label: {
            Image(systemName: "xmark") //"arrow.down.right.and.arrow.up.left"
                .foregroundStyle(.black)
                .font(.icon(18, .heavy))
        }
        .opacityPop(visible: chromeVisible)
        .allowsHitTesting(chromeVisible)
        //Its OWN value-keyed scope: the host writes bare on purpose (an animated mount
        //would flash the flight cover), so the pop cannot ride the call site's transaction
        .animation(.transition, value: chromeVisible)
    }
    
    private func loadDeclineImages() async {
        for decline in vm.declines where vm.profileImages[decline.id] == nil {
            await vm.loadProfileImages(decline.profile.profile)
        }
    }

    private func loadInviteImages() async {
        for invite in vm.sentInvites where vm.profileImages[invite.profile.id] == nil {
            await vm.loadProfileImages(invite.profile)
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
        .contentMargins(.top, -1, for: .scrollContent) //Fixes subtle spacingBug
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
            PendingInvitesView(days: vm.invitedDays,
                               expiredInvites: vm.expiredInvites,
                               ui: ui,
                               images: { vm.images(for: $0) })
        }
        .scrollPosition($pendingScroll)
        .drawerNudge(isOpen: ui.showsExpired, by: expiredReveal, position: $pendingScroll)
    }
}

//Its own Title -> Fixes bug
private struct HistoryTitle: View {
    //Injected
    let ui: HistoryUIState

    private var showsDeclines: Bool { ui.pagerProgress > 0.5 }

    var body: some View {
        ZStack(alignment: .leading) {
            Text(showsDeclines ? "Declined Profiles" : "Pending Invites")
                .font(.title(32, .bold))
                .id(showsDeclines)
                .transition(.blurReplace)
        }
        .animation(.transition, value: showsDeclines)
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


private struct HistorySubHeading: View {
    
    //Injected
    let ui: HistoryUIState

    private var showsDeclines: Bool { ui.pagerProgress > 0.5 }

    var body: some View {
        ZStack(alignment: .leading) {
            Text(showsDeclines ? recentDeclinesText : pendingInvitesText)
                .font(.body(14, .medium))
                .foregroundStyle(Color.textSecondary)
                .id(showsDeclines)
                .transition(.blurReplace)
        }
        .animation(.transition, value: showsDeclines)
    }
    
    
    private var pendingInvitesText: String {
        "Invites awaiting a reply, and the days you proposed"
    }
    
    private var recentDeclinesText: String {
        "You can still respond to them for 3 days after declining"
    }
}
