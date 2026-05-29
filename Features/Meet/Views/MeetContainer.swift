//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI
import Lottie



struct MeetContainer: View {
    
    let vm: InviteViewModel
    @State private var ui = MeetUIState()
    @State var imageSize: CGFloat = 0
    @State private var morphInviteId: String?
    // Icon frame in GLOBAL coordinates, so the morph (presented in a full-screen
    // cover above the tab bar) starts exactly on the tapped invite button.
    @State private var iconRect: CGRect = .zero
    init(vm: InviteViewModel) { self.vm = vm }

    var body: some View {
        ZStack {
            NavigationStack {
                meetView
                    .getImageSize(imageSize: $imageSize, horizontalPadding: 16)
                    .navigationTitle("Meet")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Image(systemName: "xmark")
                        }
                    }
            }

            if let profileRec = ui.openProfile { profileView(profile: profileRec)}

            if let response = ui.respondedToProfile {RespondedToProfileView(response: response)}
        }
        // Measure the tapped icon's global frame when a quick invite begins.
        .overlayPreferenceValue(InviteIconBoundsKey.self) { anchors in
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: ui.quickInvite) { _, new in
                        handleQuickInviteChange(new, anchors: anchors, proxy: proxy)
                    }
            }
        }
        // The morph lives ABOVE the TabView here, so the tab bar stays pinned behind
        // it (covered by the blur) instead of animating away.
        .fullScreenCover(isPresented: morphPresented) {
            GeometryReader { geo in
                if let id = morphInviteId {
                    QuickInviteMorph(
                        iconRect: iconRect,
                        isPresented: ui.quickInvite != nil,
                        containerSize: geo.size,
                        onDismiss: { ui.quickInvite = nil }
                    ) {
                        timeAndPlaceView(id)
                    }
                }
            }
            .ignoresSafeArea()
            .presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: $ui.showInfo) {MeetInfoCover()}
    }

    private var morphPresented: Binding<Bool> {
        Binding(get: { morphInviteId != nil },
                set: { if !$0 { morphInviteId = nil } })
    }

    // Presents/dismisses the morph cover WITHOUT the system's slide animation, so the
    // only motion is the morph itself. On present we also capture the icon's global
    // frame; on dismiss we keep the cover mounted briefly so the collapse can play.
    private func handleQuickInviteChange(_ new: String?, anchors: [String: Anchor<CGRect>], proxy: GeometryProxy) {
        if let new, let anchor = anchors[new] {
            let local = proxy[anchor]
            let origin = proxy.frame(in: .global).origin
            iconRect = CGRect(x: local.minX + origin.x, y: local.minY + origin.y,
                              width: local.width, height: local.height)
            withoutCoverAnimation { morphInviteId = new }
        } else {
            Task {
                try? await Task.sleep(for: .milliseconds(180))
                if ui.quickInvite == nil { withoutCoverAnimation { morphInviteId = nil } }
            }
        }
    }

    private func withoutCoverAnimation(_ body: () -> Void) {
        var txn = Transaction()
        txn.disablesAnimations = true
        withTransaction(txn, body)
    }
}

//Views
extension MeetContainer {
    
    private var meetView: some View {
        ScrollView {
            if vm.profiles.isEmpty {
                meetPlaceholder
            } else {
                profileCardsSection
            }
        }
        .transition(.opacity)
        .id(vm.profiles.count)
        .scrollIndicators(.hidden)
        .colorBackground()
    }

    private var profileCardsSection: some View {
        LazyVStack(spacing: 60) {
            ForEach(vm.profiles) { profile in
                ProfileCard(
                    onTap: { openProfile(profile) },
                    onQuickInvite: { ui.quickInvite = profile.profile.id },
                    profile: profile, size: imageSize,
                    imageLoader: vm.imageLoader,
                    isMorphing: morphInviteId == profile.profile.id
                )
                    .task { await vm.loadProfileImages(profile: profile.profile) }
                    .customSubtleShadow(strength: 4)//Shadow works Nicely Keep!
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 48)
        .padding(.bottom, 60)
    }
            
    private func profileView(profile: UserProfile) -> some View {
        ProfileView(
            vm: ProfileViewModel(
                profile: profile,
                imageLoader: vm.imageLoader, defaults: vm.defaults
            ),
            profileImages: vm.profileImages[profile.id] ?? [],
            mode: .sendInvite(
                onSend: { draft in
                    Task { await respondToProfile(event: draft, profile: profile) }
                },
                onDecline: {
                    Task { await respondToProfile(profile: profile) }
                }
            ),
            onDismiss: { ui.openProfile = nil }
        )
        .id(profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    @ViewBuilder private func timeAndPlaceView(_ profileId: String) -> some View {
        if let profileEvent = vm.profiles.first(where: {$0.id == profileId}) {
            let inviteModel = InviteModel(profileId: profileEvent.id, name: profileEvent.profile.name, image: profileEvent.image)
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(inviteModel: inviteModel, defaults: vm.defaults),
                showInvite: $ui.quickInvite,
                showBackdrop: false) { inviteDraft in
                    Task {await respondToProfile(event: inviteDraft, profile: profileEvent.profile)}
                }
        }
    }
}

//Functions
extension MeetContainer {
    
    private func openProfile(_ profile: PendingProfile) {
        if ui.openProfile == nil {
            ui.openProfile = profile.profile
        }
    }

    private func respondToProfile(event: EventFieldsDraft? = nil, profile: UserProfile) async {
        let isInvite = event != nil
        //1. Set a minimum of 0.75s timer for the response view to be showing
        async let minDelay: Void = Task.sleep(for: .milliseconds(850))
        ui.respondedToProfile = isInvite ? .newInvite : .decline
        
        try? await Task.sleep(for: .milliseconds(200)) //Animation is 0.18 seconds so 0.02 buffer
        //2. After 0.25 seconds either dismiss the profile, or quickInvite in background
        ui.openProfile = nil
        ui.quickInvite = nil
        
        //3. Actually send invite or decline profile
        if let event {
            try? await vm.sendInvite(event: event, profile: profile)
        } else {
            try? await vm.declineProfile(profile: profile)
        }
        
        //4.if the minimum of 0.75s done, dismiss the screen
        try? await minDelay
        ui.respondedToProfile = nil
    }
    
    private var meetPlaceholder: some View {
        VStack {
            Text("Hello World")
        }
    }
}

// MARK: - Quick invite morph

// Morphs the invite icon (a small accent circle) into the SelectTimeAndPlace card.
// A SINGLE clip window grows from the icon's frame to the card's frame while its
// corner radius relaxes from a full circle to the card radius. The real card lives
// inside that window the whole time, revealed as the window grows and cross-faded in
// over the accent fill + envelope glyph — so one surface morphs, content included.
struct QuickInviteMorph<Card: View>: View {

    let iconRect: CGRect
    let isPresented: Bool
    let containerSize: CGSize
    let onDismiss: () -> Void
    @ViewBuilder var card: () -> Card

    // Drives the entrance/exit animation independently of mount, so the window can
    // start collapsed on the icon and then animate open.
    @State private var expanded = false
    // Measured height of the real card; the window matches it so nothing clips.
    @State private var cardHeight: CGFloat = 360

    private let sideMargin: CGFloat = 30
    private var cardWidth: CGFloat { containerSize.width - sideMargin * 2 }

    // Nudge the settled card down from dead-center; the morph still starts on the
    // icon, so only the destination shifts.
    private let verticalOffset: CGFloat = 24

    private var expandedRect: CGRect {
        CGRect(x: (containerSize.width - cardWidth) / 2,
               y: (containerSize.height - cardHeight) / 2 + verticalOffset,
               width: cardWidth, height: cardHeight)
    }

    private var windowRect: CGRect { expanded ? expandedRect : iconRect }
    private var cornerRadius: CGFloat { expanded ? 30 : iconRect.height / 2 }

    var body: some View {
        ZStack {
            backdrop
            surface
            cardContent
        }
        .onAppear { DispatchQueue.main.async { expanded = true } }
        .onChange(of: isPresented) { _, presented in
            if !presented { expanded = false }
        }
        // Snappy spring on open; a quick ease-out on close so the morph clears out
        // fast and never lingers after the backdrop blur is gone.
        .animation(expanded ? .spring(response: 0.18, dampingFraction: 0.74)
                             : .easeOut(duration: 0.13), value: expanded)
        .animation(.spring(response: 0.18, dampingFraction: 0.74), value: cardHeight)
    }

    private var backdrop: some View {
        Rectangle()
            .fill(.thinMaterial)
            .ignoresSafeArea()
            .opacity(expanded ? 1 : 0)
            .allowsHitTesting(expanded)
            .onTapGesture { onDismiss() }
    }

    // The single morphing surface: the accent circle relaxes into the appCanvas card
    // background (frame + corner radius animate, accent tint fades out). No content
    // here — this is purely the card's surface travelling from the icon.
    private var surface: some View {
        ZStack {
            Color.appCanvas
            Color.accent.opacity(expanded ? 0 : 1)
        }
        .frame(width: windowRect.width, height: windowRect.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            // Card hairline stroke, faded in once open.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
                .opacity(expanded ? 1 : 0)
        }
        .overlay {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24)
                .foregroundStyle(.white)
                .opacity(expanded ? 0 : 1)
                .animation(.easeOut(duration: 0.08), value: expanded)
        }
        .shadow(color: .accent.opacity(0.15), radius: 4, y: 2)
        .shadow(color: .white.opacity(0.2), radius: 7, x: 0, y: 5)
        .position(x: windowRect.midX, y: windowRect.midY)
        .allowsHitTesting(false)
    }

    // The real card content (no background of its own), pinned at the card's FINAL
    // frame the whole time. It only cross-fades in as a whole once the surface has
    // settled — it never moves, so the content appears "already on the card" instead
    // of sliding/revealing as the surface grows.
    private var cardContent: some View {
        card()
            .frame(width: cardWidth)
            .fixedSize(horizontal: false, vertical: true)
            .background(heightReader)
            .opacity(expanded ? 1 : 0)
            // Fade in once the surface settles; on close, vanish almost instantly so
            // the content is gone before the backdrop.
            .animation(expanded ? .easeIn(duration: 0.1).delay(0.08)
                                 : nil, value: expanded)
            .position(x: expandedRect.midX, y: expandedRect.midY)
            .allowsHitTesting(expanded)
    }

    private var heightReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { cardHeight = proxy.size.height }
                .onChange(of: proxy.size.height) { _, h in cardHeight = h }
        }
    }
}

struct InviteIconBoundsKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}
