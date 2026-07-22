//
//  SendInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.

import SwiftUI

struct SendInviteCard: View {

    static let openFlight = Animation.smooth(duration: 0.3)
    static let closeFlight = Animation.smooth(duration: 0.28)
    static let confirmTransition = Animation.smooth(duration: 0.3)

    static let screenGap: CGFloat = 10
    static let sourceRadius = CornerRadius.image //Profile card image clip radius (collapsed state)
    static let cardRadius = CornerRadius.xl //Expanded card surface radius
    static let invitedCardTopPadding: CGFloat = 40
    static let confirmCardTopPadding: CGFloat = 48

    //Interactive dismiss tuning (see dismissDrag)
    static let collapseDistance: CGFloat = 300 //Vertical drag that scrubs the chrome collapse 0→1
    static let dismissThreshold: CGFloat = 0.3 //Release past this progress (or a downward flick) dismisses
    static let minDragScale: CGFloat = 0.82 //Progressive shrink of the whole card at full collapse

    //Injected
    @State var vm: TimeAndPlaceViewModel
    let image: UIImage
    let images: [UIImage]
    let details: String
    @Binding var expanded: Bool
    let sourceFrame: CGRect //Profile card image frame, global coords
    var onDismissProgress: ((Double) -> Void)? = nil //Drag collapse 0→1; the parent fades its chrome back in behind the card
    let hideInvite: () -> Void
    let sendInvite: (EventFieldsDraft) -> Void
    let declineProfile: () -> Void
    var showsCollapsedChrome: Bool = true //Meet grows from a ProfileCard (caption + button); the profile grows from a plain image, so it opts out.

    //Local view state
    @State private var cardFrame: CGRect = .zero
    @State var imageFrame: CGRect = .zero
    @State private var hasOpened = false
    @State var landed = false //True once the open flight fully lands — a pure interactivity latch (paging, drag-grab, back button)
    @State private var flightGeneration = 0 //Bumped on every close, so a land() scheduled for an earlier flight no-ops
    @State private var scrollProgress: Double = 0
    @State private var pagerPosition = ScrollPosition()
    @State private var coverImage: UIImage? //Close-from-page-N: the page flying home, fading to page 0 mid-flight
    @State var coverPage: Int? //Restores the pager if a reopen retargets that close
    @State private var invitePopupOpen = false
    @State private var confirmInviteScreen = false
    
    
    //Drag Logic
    @State var dragAxis: Axis?
    @State var dragging = false
    @State var springingBack = false
    @State var dragOffset: CGSize = .zero
    @State var dragProgress: CGFloat = 0
    @State var sendButtonTouchActive = false


    private var gallery: [UIImage] { images.isEmpty ? [image] : images }
    private var currentImageAspectRatio: AspectRatio {
        confirmInviteScreen ? .confirmInviteImage : .invitedImage
    }
    private var currentCardTopPadding: CGFloat {
        guard expanded else { return 0 }
        return confirmInviteScreen ? Self.confirmCardTopPadding : Self.invitedCardTopPadding
    }

    var body: some View {
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            ZStack(alignment: .top) {
                cardBackground(origin)
                VStack(spacing: 0) {
                    cardContent(imageWidth: geo.size.width - 2 * Self.screenGap)
                    backButton
                }
                .padding(.top, currentCardTopPadding)
                carouselLayer(origin)
                flightTapCatcher(origin)
                reopenTapTarget(origin)
            }
            .scaleEffect(1 - (1 - Self.minDragScale) * dragProgress, anchor: dragAnchor(geo.size, origin))
            .offset(dragOffset)
            .simultaneousGesture(dismissDrag)
            .onChange(of: expanded) { _, isExpanded in expandedChanged(isExpanded) }
        }
        .animation(Self.confirmTransition, value: confirmInviteScreen)
        .task {
            guard ProcessInfo.processInfo.arguments.contains("-invite-animation-autoplay") else { return }
            try? await Task.sleep(for: .seconds(3))
            confirmInviteScreen = true
            try? await Task.sleep(for: .seconds(2))
            confirmInviteScreen = false
        }
    }
}

//Card layout
extension SendInviteCard {
    
    
    
    private func cardContent(imageWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            imageSlot(imageWidth)
            sendInviteContainer
        }
        .padding(.bottom, Spacing.sm)
        .contentShape(Rectangle()) //Whole card is a drag surface, including gaps between rows
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newFrame in
            guard !dragging else { return } //Frames are the drag's model space; frozen while it owns them
            withAnimation(landed ? Self.confirmTransition : nil) { cardFrame = newFrame }
            openWhenMeasured()
        }
        .opacity(cardFrame.height > 1 ? 1 : 0) //Rows hidden until measured (the carousel, valid from frame 1, covers ProfileCard meanwhile)
        .mask { backgroundShape(cardFrame.origin)} //Revealed by the expanding background
        .allowsHitTesting(expanded && !dragging)
        .padding(.horizontal, Self.screenGap)
    }

    private func imageSlot(_ width: CGFloat) -> some View {
        return Color.clear
            .frame(width: max(width, 0), height: max(width, 0) / currentImageAspectRatio.ratio)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newFrame in
                guard !dragging else { return }
                withAnimation(landed ? Self.confirmTransition : nil) { imageFrame = newFrame }
                openWhenMeasured()
            }
    }

    private var sendInviteContainer: some View {
        InviteSectionContainer(
            name: vm.inviteModel.name,
            defaults: vm.defaults,
            draft: $vm.event,
            invitePopupOpen: $invitePopupOpen,
            confirmInviteScreen: $confirmInviteScreen,
            onSendButtonTouchChange: { sendButtonTouchActive = $0 },
            onSendInvite: {sendInvite(vm.event)}
        )
    }
    
    private var backButton: some View {
        BottomBackButton(action: closeInvite)
            .blurPop(visible: expanded && dragOffset == .zero && !invitePopupOpen && !confirmInviteScreen)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, Self.screenGap)
            .padding(.horizontal, Spacing.sm) //extra padding beyond screen padding
            .allowsHitTesting(landed && !dragging && !invitePopupOpen)
    }
}

extension SendInviteCard {

    private func carouselLayer(_ origin: CGPoint) -> some View {
        var targetImageFrame = imageFrame
        targetImageFrame.size.height = imageFrame.width / currentImageAspectRatio.ratio
        let rect = local(expanded ? targetImageFrame : sourceFrame, origin)
        return InviteImageCarousel(
            images: gallery,
            name: vm.inviteModel.name,
            details: details,
            expanded: expanded,
            scrollProgress: $scrollProgress,
            pagerPosition: $pagerPosition,
            confirmInviteScreen: $confirmInviteScreen,
            coverImage: coverImage,
            vm: vm,
            declineProfile: declineProfile,
            pagingDisabled: dragging || !landed,
            optionsVisible: expanded && dragOffset == .zero && !confirmInviteScreen,
            showsCollapsedChrome: showsCollapsedChrome
        )
        .frame(width: rect.width, height: rect.height)
        .geometryGroup() //Children resolve geometry against the in-flight frame, not the destination
        .position(x: rect.midX, y: rect.midY)
        .mask { backgroundShape(origin) } //Same shape as the background: cuts page bleed at the card edge, collapses to the source clip
        .allowsHitTesting(expanded && landed && !dragging)
    }

    private func flightTapCatcher(_ origin: CGPoint) -> some View {
        let rect = local(expanded ? imageFrame : sourceFrame, origin)
        return Color.clear
            .contentShape(Rectangle())
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .onTapGesture { closeInvite() }
            .allowsHitTesting(expanded && !landed && !dragging)
    }

    private func reopenTapTarget(_ origin: CGPoint) -> some View {
        let rect = local(sourceFrame, origin)
        return Color.clear
            .frame(width: 56, height: 56)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(Self.openFlight) { expanded = true } }
            .position(x: rect.maxX - 36, y: rect.maxY - 36) //Geometry: the 56pt square inset 8 from the corner, where the button replica sits
            .allowsHitTesting(!expanded && hasOpened)
    }

    private func cardBackground(_ origin: CGPoint) -> some View {
        backgroundShape(origin)
            .shadow(.softFloating, strength: expanded ? 1 : 0)
            .shadow(.image, strength: expanded ? 0 : 1)
            .shadow(.image, strength: expanded ? 0 : 1)
            .allowsHitTesting(false)
    }

    private func backgroundShape(_ origin: CGPoint) -> some View {
        let expandedRect = lerp(cardFrame, imageFrame, dragProgress)
        let rect = local(expanded ? expandedRect : sourceFrame, origin)
        let radius = expanded ? Self.cardRadius : Self.sourceRadius
        return RoundedRectangle(cornerRadius: radius)
            .fill(Color.appCanvas)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }

    private func local(_ rect: CGRect, _ origin: CGPoint) -> CGRect {
        rect.offsetBy(dx: -origin.x, dy: -origin.y)
    }
}

//Open/landing state machine
extension SendInviteCard {
    
    private func openWhenMeasured() {
        guard !hasOpened, imageFrame.height > 50, cardFrame.height > 50 else { return }
        hasOpened = true
        let generation = flightGeneration
        Task { @MainActor in
            withAnimation(sourceFrame.width > 1 ? Self.openFlight : nil, completionCriteria: .removed) {
                expanded = true
            } completion: {
                land(generation)
            }
        }
    }

    private func expandedChanged(_ isExpanded: Bool) {
        if isExpanded {
            dragging = false //A reopen mid-close revives the card; unfreeze frames and hand hits back
            springingBack = false
            let generation = flightGeneration
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                land(generation)
            }
        } else {
            flightGeneration += 1
            landed = false
        }
    }

    private func land(_ generation: Int) {
        guard expanded, generation == flightGeneration else { return } //A newer close/reopen owns the flight now
        landed = true
        if let coverPage, coverImage != nil {
            snapPager { $0.scrollTo(id: coverPage, anchor: .leading) }
        }
        coverImage = nil
        coverPage = nil
    }

    func closeInvite() {
        prepareClose()
        hideInvite()
    }

    private func prepareClose() {
        let page = currentPage
        if page != 0 {
            coverImage = gallery[page]
            coverPage = page
        } else if scrollProgress > 0.001 {
            coverImage = gallery[0] //Close mid-flick near page 0: the cover hides the unanimated snap
        }
        snapPager { $0.scrollTo(edge: .leading) }
    }

    var currentPage: Int {
        min(max(Int(scrollProgress.rounded()), 0), gallery.count - 1)
    }

    func snapPager(_ move: (inout ScrollPosition) -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { move(&pagerPosition) }
    }
}
