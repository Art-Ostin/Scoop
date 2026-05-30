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
        // Morphs the tapped invite icon into the time-and-place card. Presented above
        // the TabView so the tab bar stays pinned behind its blur.
        .quickInviteMorph(iconId: $ui.quickInvite, morphInviteId: $morphInviteId) { id in
            timeAndPlaceView(id)
        }
        .fullScreenCover(isPresented: $ui.showInfo) {MeetInfoCover()}
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
        LazyVStack(spacing: 84) {
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

// MARK: - Quick invite morph presenter

extension View {
    /// Morphs `card` out of the invite icon whose `InviteIconBoundsKey` matches the
    /// driving id. Drive `iconId` with the tapped invite source's id to present, and
    /// set it to nil to collapse the morph back onto the icon. `morphInviteId` is the
    /// cover-mount state, owned by the caller so it can hide the real icon (avoiding a
    /// duplicate) while the morph is live — it outlasts `iconId` through the collapse.
    func quickInviteMorph<Card: View>(
        iconId: Binding<String?>,
        morphInviteId: Binding<String?>,
        @ViewBuilder card: @escaping (String) -> Card
    ) -> some View {
        modifier(QuickInviteMorphPresenter(iconId: iconId, morphInviteId: morphInviteId, card: card))
    }
}

private struct QuickInviteMorphPresenter<Card: View>: ViewModifier {
    @Binding var iconId: String?
    @Binding var morphInviteId: String?
    @ViewBuilder let card: (String) -> Card

    // Icon frame in GLOBAL coordinates, so the morph (presented in a full-screen cover
    // above the tab bar) starts exactly on the tapped invite button.
    @State private var iconRect: CGRect = .zero

    func body(content: Content) -> some View {
        content
            // Measure the tapped icon's global frame when a quick invite begins.
            .overlayPreferenceValue(InviteIconBoundsKey.self) { anchors in
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: iconId) { _, new in
                            handleChange(new, anchors: anchors, proxy: proxy)
                        }
                }
            }
            .fullScreenCover(isPresented: morphPresented) {
                GeometryReader { geo in
                    if let id = morphInviteId {
                        QuickInviteMorph(
                            iconRect: iconRect,
                            isPresented: iconId != nil,
                            containerSize: geo.size,
                            onDismiss: { iconId = nil }
                        ) {
                            card(id)
                        }
                    }
                }
                .ignoresSafeArea()
                .presentationBackground(.clear)
            }
    }

    private var morphPresented: Binding<Bool> {
        Binding(get: { morphInviteId != nil },
                set: { if !$0 { morphInviteId = nil } })
    }

    // Presents/dismisses the morph cover WITHOUT the system's slide animation, so the
    // only motion is the morph itself. On present we also capture the icon's global
    // frame; on dismiss we keep the cover mounted briefly so the collapse can play.
    private func handleChange(_ new: String?, anchors: [String: Anchor<CGRect>], proxy: GeometryProxy) {
        if let new, let anchor = anchors[new] {
            let local = proxy[anchor]
            let origin = proxy.frame(in: .global).origin
            iconRect = CGRect(x: local.minX + origin.x, y: local.minY + origin.y,
                              width: local.width, height: local.height)
            withoutCoverAnimation { morphInviteId = new }
        } else {
            Task {
                // Outlast the spring collapse so the cover stays mounted until the
                // morph has fully folded back onto the icon.
                try? await Task.sleep(for: .milliseconds(420))
                if iconId == nil { withoutCoverAnimation { morphInviteId = nil } }
            }
        }
    }

    private func withoutCoverAnimation(_ body: () -> Void) {
        var txn = Transaction()
        txn.disablesAnimations = true
        withTransaction(txn, body)
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

    // One spring drives every animated property (frame, corner, fills, content
    // opacity) so the whole morph interpolates together like a `.contentTransition`,
    // rather than a snap followed by a staggered fade. The slight bounce gives the
    // iOS 26 "gel" settle. The collapse runs a touch quicker than the open.
    private let openAnimation: Animation = .spring(duration: 0.35, bounce: 0.2)
    private let closeAnimation: Animation = .spring(duration: 0.26, bounce: 0.18)
    private var morphAnimation: Animation { expanded ? openAnimation : closeAnimation }

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
        .animation(morphAnimation, value: expanded)
        .animation(morphAnimation, value: cardHeight)
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
        }
        .shadow(color: .accent.opacity(0.15), radius: 4, y: 2)
        .shadow(color: .white.opacity(0.2), radius: 7, x: 0, y: 5)
        .position(x: windowRect.midX, y: windowRect.midY)
        .allowsHitTesting(false)
    }

    // The real card content (no background of its own), pinned at the card's FINAL
    // frame the whole time. Opacity is staged off the shared morph curve: it fades in
    // only AFTER the surface has grown behind it, and fades out FAST on close so it's
    // gone before the surface collapses away — otherwise content floats with no
    // background behind it.
    private var cardContent: some View {
        card()
            .frame(width: cardWidth)
            .fixedSize(horizontal: false, vertical: true)
            .background(heightReader)
            .opacity(expanded ? 1 : 0)
            .animation(expanded ? .easeIn(duration: 0.14).delay(0.16)
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
