//
//  SendInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.

import SwiftUI

struct SendInviteCard: View {

    static let openFlight = Animation.smooth(duration: 0.3)
    static let closeFlight = Animation.smooth(duration: 0.28)

    //Concentric geometry, derived from CardImageScrollView so the flight radii always match the settled carousel.
    //TODO: flight pass — the settled carousel insets its image by imagePadding and blurs at a different radius; the flight copy doesn't match yet.
    static let cardRadius = 24
    static let imageRadius = 24 //Expanded image top corners
    static let imageBottomRadius = 24 //Expanded image bottom corners
    static let screenGap: CGFloat = 10
    static let sourceRadius = CornerRadius.image //Profile card image clip radius (collapsed state)
    static let imageHeightRatio: CGFloat = 1.05
    static let nameBlurInset: CGFloat = 10

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

    //Local view state
    @State private var cardFrame: CGRect = .zero
    @State private var imageFrame: CGRect = .zero
    @State private var hasOpened = false
    @State private var settled = false //True once the open flight lands; swaps the flight copy for the live carousel
    @State private var scrollProgress: Double = 0

    //Interactive dismiss: a drag scrubs the close (chrome collapse + shrink) before the release flight commits it.
    @State private var dragAxis: Axis? //Decided once per gesture; horizontal is voided (belongs to the pager)
    @State private var dragging = false //Freezes the measured frames and owns the single on-screen image
    @State private var springingBack = false //Cancel spring in flight; new grabs are declined until it lands
    @State private var dragOffset: CGSize = .zero //Rubber-banded finger tracking
    @State private var dragProgress: CGFloat = 0 //0 = expanded card, 1 = image only
    @State private var dragImage: UIImage? //Carousel page under the finger; the flight carries it home

    private var gallery: [UIImage] { images.isEmpty ? [image] : images }

    var body: some View {
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            ZStack(alignment: .top) {
                cardBackground(origin)
                VStack(spacing: 0) {
                    cardContent(imageWidth: geo.size.width - 2 * (Self.screenGap + 24))
                    backButton
                }
                flight(origin)
            }
            .scaleEffect(1 - (1 - Self.minDragScale) * dragProgress, anchor: dragAnchor(geo.size, origin))
            .offset(dragOffset)
            .simultaneousGesture(dismissDrag)
            .onChange(of: expanded) { _, isExpanded in expandedChanged(isExpanded) }
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
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
            guard !dragging else { return } //Frames are the drag's model space; frozen while it owns them
            cardFrame = $0
            openWhenMeasured()
        }
        .opacity(cardFrame.height > 1 ? 1 : 0) //Nothing shows until measured
        .mask { backgroundShape(cardFrame.origin) } //Revealed by the expanding background
        .allowsHitTesting(expanded && !dragging)
        .padding(.horizontal, Self.screenGap)
    }

    private func imageSlot(_ width: CGFloat) -> some View {
        Color.clear
            .frame(width: max(width, 0), height: max(width, 0) * Self.imageHeightRatio)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                guard !dragging else { return }
                imageFrame = $0
                openWhenMeasured()
            }
            .overlay { carousel }
    }

    //Page one sits exactly under the flight copy, so the settled swap never shows.
    private var carousel: some View {
        InviteImageCarousel(
            images: gallery,
            name: vm.inviteModel.name,
            scrollProgress: $scrollProgress,
            vm: vm,
            dragDisabled: dragging,
            optionsVisible: expanded && dragOffset == .zero
        )
        .opacity(settled ? 1 : 0)
        .allowsHitTesting(settled)
    }

    private var sendInviteContainer: some View {
        SendInviteContainer(
            draft: $vm.event,
            name: vm.inviteModel.name,
            isInviteResponse: false,
            defaults: vm.defaults,
            onSendInvite: { sendInvite(vm.event) }
        )
    }

    private var backButton: some View {
        
    BottomBackButton(action: hideInvite)
        .blurPop(visible: expanded && dragOffset == .zero)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, Self.screenGap)
        .padding(.horizontal, 12) //12 extra padding beyond screen padding
        .allowsHitTesting(settled)
    }
}

//Flight copy + expanding background
extension SendInviteCard {

    private func flight(_ origin: CGPoint) -> some View {
        SendInviteFlight(
            image: image,
            name: vm.inviteModel.name,
            details: details,
            rect: local(expanded ? imageFrame : sourceFrame, origin),
            expanded: $expanded,
            settled: settled,
            dragImage: dragImage,
            dragging: dragging,
            optionsVisible: expanded && dragOffset == .zero,
            hideInvite: hideInvite
        )
    }

    private func cardBackground(_ origin: CGPoint) -> some View {
        backgroundShape(origin)
            //Expanded, the card is a modal surface: top-of-ramp elevation, halved so
            //the near-fullscreen sheet keeps only a hint of edge while dragged.
            .shadow(.softFloating, strength: expanded ? 1 : 0)
            //ProfileCard's resting shadow (its .shadow(.image) + MeetContainer's wrapper = twice),
            //worn by the flight while collapsed: the shadow morphs in DURING the close and is already
            //complete the frame the card lands, so the unmount handoff to the real ProfileCard (which
            //waits for the spring's .removed tail) swaps pixel-identically instead of popping in late.
            //Same fix in reverse on open: the slot's shadow hands off to the flight with no gap.
            .shadow(.image, strength: expanded ? 0 : 1)
            .shadow(.image, strength: expanded ? 0 : 1)
            .allowsHitTesting(false)
    }

    private func backgroundShape(_ origin: CGPoint) -> some View {
        let expandedRect = lerp(cardFrame, imageFrame, dragProgress)
        let rect = local(expanded ? expandedRect : sourceFrame, origin)
        let radius = expanded ? 24 : Self.sourceRadius
        return RoundedRectangle(cornerRadius: radius)
            .fill(Color.appCanvas)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }

    private func local(_ rect: CGRect, _ origin: CGPoint) -> CGRect {
        rect.offsetBy(dx: -origin.x, dy: -origin.y)
    }
}

//Open/settle state machine
extension SendInviteCard {

    //Opens only once both frames are measured AND a collapsed frame has rendered: the 30ms sleep
    //crosses a real frame boundary (a bare MainActor hop runs before the CA commit and the card snaps).
    private func openWhenMeasured() {
        guard !hasOpened, imageFrame.height > 50, cardFrame.height > 50 else { return }
        hasOpened = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(30))
            //.removed: the settle swap must wait for the spring's true end, not its perceptual duration.
            withAnimation(sourceFrame.width > 1 ? Self.openFlight : nil, completionCriteria: .removed) {
                expanded = true
            } completion: {
                settled = expanded
            }
        }
    }

    //A reopen mid-close retargets the spring from MeetContainer (no completion reaches us),
    //so re-settle on a timer sized past the spring's full removal.
    private func expandedChanged(_ isExpanded: Bool) {
        if isExpanded {
            dragging = false //A reopen mid-close revives the card; unfreeze frames and hand hits back
            springingBack = false
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                if expanded {
                    settled = true
                    dragImage = nil //Flight is hidden from here; a future drag recaptures the page
                }
            }
        } else {
            settled = false
        }
    }
}



//Interactive swipe-to-dismiss: a vertical drag anywhere on the card scrubs the chrome collapse and
//rubber-bands the card after the finger; release either flies home through the shared close flight
//or springs back open. Modeled on the zoom transition's interactive dismiss.
extension SendInviteCard {

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if dragAxis == nil {
                    let vertical = abs(value.translation.height) >= abs(value.translation.width)
                    let canBegin = expanded && settled && !springingBack //Only a landed card is grabbable
                    if vertical && canBegin { dragAxis = .vertical; beginDrag() }
                    else { dragAxis = .horizontal } //Voided: horizontal belongs to the pager
                }
                guard dragAxis == .vertical, dragging, expanded else { return }
                let t = value.translation
                dragProgress = min(max(t.height / Self.collapseDistance, 0), 1)
                onDismissProgress?(dragProgress)
                dragOffset = CGSize(
                    width: rubberBand(t.width, limit: 160, response: 0.8),
                    height: t.height >= 0
                        ? rubberBand(t.height, limit: 700, response: 1)
                        : rubberBand(t.height, limit: 80, response: 0.9) //Upward fights back hard
                )
            }
            .onEnded { value in
                let owned = dragAxis == .vertical && dragging
                dragAxis = nil
                guard owned, expanded else { return }
                let flick = value.predictedEndTranslation.height - value.translation.height
                if dragProgress > Self.dismissThreshold || (value.translation.height > 20 && flick > 90) {
                    finishDismiss()
                } else {
                    cancelDrag()
                }
            }
    }

    private func beginDrag() {
        dragging = true //Freezes cardFrame/imageFrame and gates row hit-testing
        let page = min(max(Int(scrollProgress.rounded()), 0), gallery.count - 1)
        dragImage = gallery[page] //The flight copy shows exactly what the carousel showed
        settled = false //Swap to the flight copy: the drag owns the single on-screen image
    }

    //Fly home from wherever the finger left off: the drag transforms animate to identity with the
    //same spring MeetContainer runs on `expanded`, so both compose into one motion into the slot.
    private func finishDismiss() {
        withAnimation(Self.closeFlight) {
            dragProgress = 0
            dragOffset = .zero
            onDismissProgress?(0)
        }
        hideInvite()
    }

    private func cancelDrag() {
        springingBack = true
        withAnimation(Self.openFlight, completionCriteria: .removed) {
            dragProgress = 0
            dragOffset = .zero
            onDismissProgress?(0)
        } completion: {
            springingBack = false
            guard expanded else { return } //A close started mid-spring; leave state to that flight
            settled = true
            dragging = false
            dragImage = nil
        }
    }

    //Asymptotic rubber band: tracks at ~response·d near zero, saturating at `limit`.
    private func rubberBand(_ d: CGFloat, limit: CGFloat, response: CGFloat) -> CGFloat {
        guard d != 0 else { return 0 }
        let m = abs(d) * response
        return (1 - 1 / (m / limit + 1)) * limit * (d < 0 ? -1 : 1)
    }

    private func dragAnchor(_ size: CGSize, _ origin: CGPoint) -> UnitPoint {
        guard imageFrame.height > 1, size.width > 1, size.height > 1 else { return .center }
        return UnitPoint(x: (imageFrame.midX - origin.x) / size.width,
                         y: (imageFrame.midY - origin.y) / size.height)
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    private func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
        CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
               width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
    }
}
