//
//  RespondContainer.swift
//  Scoop
//
//  Created by Art Ostin on 28/07/2026.
//

import SwiftUI

struct RespondInviteContainer: View {

    //Injected Properties
    let images: [UIImage]

    @State var vm: RespondViewModel
    @State var timeAndPlaceVM: TimeAndPlaceViewModel

    //A per-card Bool (InviteSlot's guarded narrowing of the shared EventProfile? slot), never
    //the slot itself: a stale close completion writing the raw slot nil would dismiss whichever
    //card presented AFTER this one — the id-guarded setter makes that write a no-op.
    @Binding var showInvite: Bool

    let respond: (ProfileResponse) -> ()

    @State var ui = RespondUIState()
    @State var timeAndPlaceUI = TimeAndPlaceUIState()

    //The flight's source anchor and chrome, exactly as SendInviteContainer reads them. The
    //anchor is LIVE (the presenter rides the hidden card's geometry reports). Nil outside an
    //.inviteZoom presentation — a direct mount keeps the old instant open/close.
    @Environment(InviteZoomPresenter.self) private var zoom: InviteZoomPresenter?

    //Both palette variants of the card's artwork: .subtle drives the backdrop and seam wash
    //(the invite popup's own family, warmed by InviteSlot), the card variant tints the hero
    //rows so they lift off wearing exactly the resting card's hue.
    @State private var palette: OverlayPalette = .placeholder
    @State private var cardPalette: OverlayPalette = .placeholder

    //Flight state — continuous scalars so the drag scrub, the chrome race and the position
    //flight compose additively on the same geometry (the SendInviteContainer machine; the
    //clocks and constants are shared statics there, so the two popups can't drift apart)
    @State private var closeP: CGFloat = 1 //1 = collapsed at the source card, 0 = landed popup
    @State private var chromeRaceP: CGFloat = 0
    @State private var expanded = false
    @State private var hasOpened = false
    @State private var landed = false
    @State private var flightGeneration = 0
    @State private var cardFrame: CGRect = .zero
    @State private var imageFrame: CGRect = .zero
    @State private var scrollProgress: Double = 0
    @State private var pagerPosition = ScrollPosition()
    @State private var coverPage: Int?
    @State private var coverFade: Double = 1
    @State private var pagerReveal: Double = 0
    @State private var coversDropped = false
    @State private var blurCover: Double = 0
    @State private var sourceChromeFade: Double = 1
    @State private var chromeIn = false
    @State private var chevronIn = false
    @State private var sourceChromeExiting = false
    @State private var flightTargets: (card: CGRect, image: CGRect)?

    //The hero text layers: the card's title, type chip, time and place rows never blink —
    //they fly as always-mounted layers from the card's derived anchors to the popup's
    //measured rows, restyling en route. rowsLanded hands the words back to the real layout a
    //beat after land(); heroesEngaged is false when the popup isn't showing the rows the
    //heroes would land on (a persisted new-event draft) — the chrome copy's own text wears
    //the chromeFade exits instead.
    @State private var rowsLanded = false
    @State private var heroesEngaged = false
    @State private var typeRowDest: CGRect = .zero
    @State private var timeRowDest: CGRect = .zero
    @State private var placeRowDest: CGRect = .zero
    @State private var acceptDest: CGRect = .zero //The CTA hero's landing pad: the real Accept button's frame

    //Drag Logic — the ported profile dismissal, exactly as SendInviteContainer carries it
    @State private var dragAxis: Axis?
    @State private var flightLink = GestureFlightLink()
    @State private var gestureFlight: GestureFlight?
    @State private var dragStart: CGSize = .zero
    @State private var regrabProgress: CGFloat?
    @State private var regrabOffset: CGSize = .zero
    @State private var cropScrub: CGFloat = 0
    @State private var dragging = false
    @State private var springingBack = false
    @State private var dragOffset: CGSize = .zero
    @State private var dragProgress: CGFloat = 0
    @State private var actionMenuHitArea: CGRect = .zero

    private var sourceFrame: CGRect { zoom?.source ?? .zero }
    private var hasFlight: Bool { sourceFrame.width > 1 }
    private var shown: Bool { expanded || !hasFlight }

    //The heroes own the card's text set for the whole presentation; the real rows take over
    //at rest. Never engaged toward a screen without the rows (new-event mode).
    private var rowsHeroActive: Bool {
        hasFlight && heroesEngaged && (!rowsLanded || !expanded)
    }

    private var chromeMix: CGFloat { min(max(dragProgress, chromeRaceP), 1) }
    private var gestureClosing: Bool { gestureFlight != nil && !expanded && hasOpened }
    private var currentRadius: CGFloat { lerp(SendInviteContainer.cardRadius, SendInviteContainer.sourceRadius, closeP) }

    var createEventScreen: Bool {
        (vm.respondDraft.respondType == .newEvent && !(timeAndPlaceUI.showConfirmScreen ?? true))
    }

    //Answering their invite until you counter with an event of your own, which pages like the send card
    private var carouselScreen: InviteScreen {
        guard vm.responseType == .newEvent else { return .accept }
        return timeAndPlaceUI.showConfirmScreen == true ? .newInviteConfirm : .newInvite
    }

    private var currentImageAspect: AspectRatio {
        carouselScreen.chrome.compactImage ? .confirmInviteImage : .invitedImage
    }

    private var inviteSummary: InviteSummary { InviteSummary(event: vm.respondDraft.originalInvite.event) }

    var body: some View {
        ZStack {
            backdrop
            flightCard
        }
        .task(id: vm.profile.id) { await fetchColour() }
        .task(id: timeAndPlaceUI.activePopup) { await timeAndPlaceUI.syncDelayedPopups() } //Owned here: the confirm page carries the time menu but never mounts TimeAndPlacePage
        .sheet(isPresented: $timeAndPlaceUI.showInfoScreen) {Text("How It works")}
        .animation(.move, value: vm.responseType)
        .animation(.move, value: createEventScreen)
        .animation(.toggle, value: vm.respondDraft.newEvent.isComplete)
        .sheet(isPresented: $timeAndPlaceUI.showMessageScreen) {addMessageView }
        .fullScreenCover(isPresented: $timeAndPlaceUI.showMapView) { MapView(defaults: vm.defaults, eventLocation: $vm.respondDraft.newEvent.place) }
    }
}

//The flight chassis — SendInviteContainer's, with the respond card's layout inside it: a glass
//surface, the real layout, a frame-animated image layer and the source chrome copy, all cut by
//one mask, plus the four hero text layers that keep the card's words on screen the whole way.
extension RespondInviteContainer {

    private var backdrop: some View {
        InvitePopupBackground(tint: palette.secondaryText)
            //Pure function of the flight scalars (see SendInviteContainer.backdrop): fades in
            //over the open, scrubs 1:1 with the drag and the gesture flights. Clamped: the
            //dive overshoots closeP past 1.
            .opacity(max(0, Double((1 - chromeMix) * (1 - closeP))))
            .animation(.transition, value: palette) //Extraction lands a frame late — the tint fades in rather than snaps
    }

    private var flightCard: some View {
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            ZStack(alignment: .top) {
                cardSurface(origin)
                layoutColumn
                carouselLayer(origin)
                sourceChromeLayer(origin)
                titleHeroLayer(origin)
                typeHeroLayer(origin)
                timeHeroLayer(origin)
                placeHeroLayer(origin)
                ctaHeroLayer(origin)
                flightTapCatcher(origin)
                reopenTapTarget(origin)
            }
            .scaleEffect(1 - (1 - DragTuning.minDragScale) * dragProgress, anchor: dragAnchor(geo.size, origin))
            .offset(dragOffset)
            //ABOVE the pose modifiers, deliberately: the chevron never rides the drag or the
            //flights — it only ever fades in place (SendInviteContainer's rule)
            .overlay(alignment: .top) { stationaryBackButton(origin) }
            .simultaneousGesture(dismissDrag(origin))
            .onChange(of: expanded) { _, isExpanded in expandedChanged(isExpanded) }
        }
    }

    //The card's surface and shadow, worn by the flying rect rather than the content — the
    //flight flies a plain appCanvas fill; the real glass crossfades in at landing (see
    //SendInviteContainer.cardSurface for the measured reasoning).
    private func cardSurface(_ origin: CGPoint) -> some View {
        let rect = maskRect(origin)
        let contact = flightShadowLayer(SendInviteContainer.landedShadow.contact, SendInviteContainer.sourceShadow.contact)
        let ambient = flightShadowLayer(SendInviteContainer.landedShadow.ambient, SendInviteContainer.sourceShadow.ambient)
        return ZStack {
            RoundedRectangle(cornerRadius: currentRadius)
                .fill(Color.appCanvas)
            Color.clear
                .containerGlassEffect(tint: Color.appCanvas, clipped: true, shape: RoundedRectangle(cornerRadius: currentRadius))
                .opacity(landed ? 1 : 0)
        }
        .animation(.transition, value: landed)
        .frame(width: rect.width, height: rect.height)
        //Raw .shadow, sanctioned as a measured spec that interpolates geometry: the source
        //card's resting composite travels into .softFloating with opacity, radius AND offset
        //all lerped on the flight clock (SendInviteContainer's spec — the invite card wears
        //the same UIKit resting shadow the meet card does)
        .shadow(color: .black.opacity(contact.opacity), radius: contact.radius, x: 0, y: contact.y)
        .shadow(color: .black.opacity(ambient.opacity), radius: ambient.radius, x: 0, y: ambient.y)
        .position(x: rect.midX, y: rect.midY)
        .allowsHitTesting(false)
    }

    private func flightShadowLayer(_ landed: Elevation.Layer, _ source: Elevation.Layer) -> Elevation.Layer {
        Elevation.Layer(opacity: Double(lerp(CGFloat(landed.opacity), CGFloat(source.opacity), closeP)),
                        radius: lerp(landed.radius, source.radius, closeP),
                        y: lerp(landed.y, source.y, closeP))
    }

    //The real layout, centred as the static screen was. The chevron keeps a LAYOUT GHOST so
    //the column centres exactly as before while the visible button renders stationary above
    //the pose (SendInviteContainer's rule).
    private var layoutColumn: some View {
        VStack(spacing: Spacing.xl) {
            cardColumn
            BottomBackButton(visible: false) { }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    //The card content at its final layout; the expanding mask reveals it. The image layer is a
    //separate flight layer above — the imageSlot only reserves its place.
    private var cardColumn: some View {
        VStack(spacing: 0) { //Butted, same as the send card — a gap here shows the card's glass as a white seam
            imageSlot
            inviteDetailsSection
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.sm)
        .contentShape(Rectangle()) //Whole card is a drag surface, including gaps between rows
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newFrame in
            guard !dragging, gestureFlight == nil else { return } //Frames are the drag's model space; frozen while the finger OR the flight driver owns them
            retargetFrozenFlight(card: newFrame)
            //.move, matching THIS screen's swap clock (.animation(.move, value: responseType))
            //so the mask glides on the same curve the content reflows on
            withAnimation(landed ? .move : nil) { cardFrame = newFrame }
            openWhenMeasured()
        }
        .opacity(cardFrame.height > 1 ? 1 : 0) //Hidden until measured (the cover, valid from frame 1, matches the source meanwhile)
        .mask { maskShape(cardFrame.origin) } //Revealed by the expanding shape
        .allowsHitTesting(expanded && !dragging)
        //While the heroes own the words the real rows keep layout ghosts (opacity only — a
        //structural unmount mid-flight resolves its return at destination geometry)
        .environment(\.inviteRowsFlying, rowsHeroActive)
        .padding(.horizontal, InviteCardBackground.horizontalInset)
        .padding(.top, InviteCardBackground.topInset)
    }

    private var imageSlot: some View {
        //The wash backstop: a bouncy open that overshoots the image above its slot must read
        //as the wash, never as bare appCanvas (SendInviteContainer's rule)
        palette.secondaryText.opacity(0.45)
            .aspectRatio(currentImageAspect.ratio, contentMode: .fit)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newFrame in
                guard !dragging, gestureFlight == nil else { return }
                retargetFrozenFlight(image: newFrame)
                withAnimation(landed ? .move : nil) { imageFrame = newFrame } //As the card frame: the screen's own swap clock
                openWhenMeasured()
            }
    }

    private func carouselLayer(_ origin: CGPoint) -> some View {
        let rect = local(lerp(carouselTargetFrame, sourceFrame, closeP), origin)

        return ZStack {
            //The seam wash lives UNDER the covers, so the landed seam colour is already
            //there when the card arrives
            palette.secondaryText.opacity(0.45)
            flightCovers //Static stand-ins beneath the chrome: the live pager only exists at rest
            imageSection
        }
        .frame(width: rect.width, height: rect.height)
        .geometryGroup() //Children resolve geometry against the in-flight frame, not the destination
        .position(x: rect.midX, y: rect.midY)
        .mask { maskShape(origin) }
        .allowsHitTesting(expanded && landed && !dragging)
    }

    //A copy of the invite card's chrome riding the flying image: the blur + scrim rush out at
    //launch and ride the collapse back in, the envelope pops on its own clocks, and the text
    //set never renders here while the heroes own it (inviteRowsFlying).
    @ViewBuilder
    private func sourceChromeLayer(_ origin: CGPoint) -> some View {
        if hasFlight, let chrome = zoom?.slot?.sourceChrome {
            let rect = local(lerp(carouselTargetFrame, sourceFrame, closeP), origin)
            chrome()
                .frame(width: sourceFrame.width, height: sourceFrame.height)
                .clipShape(RoundedRectangle(cornerRadius: SendInviteContainer.sourceRadius))
                .environment(\.inviteChromeFade, min(Double(closeP), sourceChromeFade))
                .environment(\.inviteChromeCollapse, Double(closeP))
                .environment(\.inviteChromeExiting, sourceChromeExiting)
                .environment(\.inviteRowsFlying, rowsHeroActive)
                .scaleEffect(x: rect.width / max(sourceFrame.width, 1),
                             y: rect.height / max(sourceFrame.height, 1))
                .position(x: rect.midX, y: rect.midY)
                .allowsHitTesting(false)
        }
    }

    private func flightTapCatcher(_ origin: CGPoint) -> some View {
        let rect = local(lerp(targetImageFrame, sourceFrame, closeP), origin)
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
            .onTapGesture { reopen() }
            .position(x: rect.maxX - 45, y: rect.maxY - 45) //Geometry: the card's envelope button centre — content inset 24 + half the 42pt circle
            .allowsHitTesting(!expanded && hasOpened)
    }

    //The flight's static image stand-ins, always mounted (a view inserted mid-flight resolves
    //at destination geometry — SendInviteContainer's rule). The hero cover is sharp raw
    //pixels: the accept screen's pages carry no bottom blur, so there is no band to bake. The
    //page snapshot keeps its glur variant for a close off a blurred new-invite page, lit only
    //for the frame the pager unmounts and faded out over the chrome race.
    @ViewBuilder
    private var flightCovers: some View {
        if !images.isEmpty {
            let snapshotImage = images[min(coverPage ?? 0, images.count - 1)]
            ZStack {
                ZStack {
                    rawCover(snapshotImage)
                    InvitePagePhoto(image: snapshotImage, blursBottom: carouselScreen.blursBottom)
                        .opacity(blurCover)
                }
                .opacity(coverPage != nil ? 1 : 0)
                rawCover(images[0])
                    .opacity(coverFade)
            }
            //The pager page's own 2pt bottom fade, worn once by the whole cover stack — the
            //covers dissolve into the wash beneath exactly like a resting page
            .mask {
                VStack(spacing: 0) {
                    Rectangle()
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 2)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func rawCover(_ image: UIImage) -> some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
    }

    //A flight animates toward FROZEN copies of the measured frames — live measurements resume
    //at landing (SendInviteContainer's rule).
    private var targetCardFrame: CGRect { flightTargets?.card ?? cardFrame }
    private var targetImageFrame: CGRect { flightTargets?.image ?? imageFrame }

    //A DELIBERATE reflow under the freeze (the new-event toggle mid-open) glides the frozen
    //targets; sub-point settles never retarget.
    private func retargetFrozenFlight(card: CGRect? = nil, image: CGRect? = nil) {
        guard expanded, hasOpened, let targets = flightTargets else { return }
        if let card, abs(card.height - targets.card.height) > 8 || abs(card.minY - targets.card.minY) > 8 {
            withAnimation(.move) { flightTargets?.card = card } //The screen's own swap clock (.move), unlike the send card's .transition
        }
        if let image, abs(image.height - targets.image.height) > 8 || abs(image.minY - targets.image.minY) > 8 {
            withAnimation(.move) { flightTargets?.image = image }
        }
    }

    //The carousel's destination frame — height derived from the width and the current aspect.
    //A gesture close scrubs the height toward the SOURCE aspect (cropScrub) so the ascent
    //flies a rigid frame. Top-anchored: the crop extends downward.
    private var carouselTargetFrame: CGRect {
        var target = targetImageFrame
        let invited = targetImageFrame.width / currentImageAspect.ratio
        let source = sourceFrame.width > 1
            ? targetImageFrame.width * (sourceFrame.height / sourceFrame.width)
            : invited
        target.size.height = lerp(invited, source, cropScrub)
        return target
    }

    //Chrome axis first (card → image-only), flight axis second (→ source)
    private func maskRect(_ origin: CGPoint) -> CGRect {
        let chromeRect = lerp(targetCardFrame, carouselTargetFrame, chromeMix)
        return local(lerp(chromeRect, sourceFrame, closeP), origin)
    }

    private func maskShape(_ origin: CGPoint) -> some View {
        let rect = maskRect(origin)
        return RoundedRectangle(cornerRadius: currentRadius)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }

    private func local(_ rect: CGRect, _ origin: CGPoint) -> CGRect {
        rect.offsetBy(dx: -origin.x, dy: -origin.y)
    }

    private func local(_ point: CGPoint, _ origin: CGPoint) -> CGPoint {
        CGPoint(x: point.x - origin.x, y: point.y - origin.y)
    }
}

//MARK: The hero text layers — the card's words never blink

//The resting invite card's text geometry, derived from the card's frame + the card overlay's
//layout constants and font metrics (InviteSlot.cardOverlay / ConfirmContainer .card / the
//TypeButton chip). DERIVED, never measured — the flight's anchors must be pure functions of
//the frozen source rect, and a measured anchor proved lossy on device (the meet card's
//nameRect rule).
private enum SourceCardLayout {
    static let contentInset: CGFloat = Spacing.lg //ConfirmContainer's horizontal padding
    static let bottomInset: CGFloat = 28          //InviteCard's own bottom inset under the rows
    static let rowGap: CGFloat = Spacing.lg       //TimeAndPlaceRows' spacing
    static let rowsTopGap: CGFloat = 24           //ConfirmStyle.card.timeAndPlaceTopPadding
    static let chipOffsetY: CGFloat = 4.5         //TypeButton's optical offset
    static let chipHeight: CGFloat = 25
    static let chipLeadingPad: CGFloat = 6
    static let chipTrailingPad: CGFloat = 8
    static let chipInnerGap: CGFloat = Spacing.xxs
    static let envelopeSize: CGFloat = 42         //InviteButton's circle
    static let envelopeOffsetY: CGFloat = 4       //Its optical drop below the rows' bottom edge
}

extension RespondInviteContainer {

    private struct SourceAnchors {
        var timeCenter: CGPoint
        var placeCenter: CGPoint
        var titleRect: CGRect
        var chipRect: CGRect
    }

    private func sourceAnchors(in card: CGRect) -> SourceAnchors {
        let inset = SourceCardLayout.contentInset
        let textH = UIFont.body(20, .medium).lineHeight
        let timeH = max(textH, UIImage(resource: .whiteClock).size.height)
        let placeH = max(textH, UIImage(resource: .whiteMap).size.height)
        let left = card.minX + inset

        let placeCenterY = card.maxY - SourceCardLayout.bottomInset - placeH / 2
        let timeCenterY = card.maxY - SourceCardLayout.bottomInset - placeH - SourceCardLayout.rowGap - timeH / 2
        let titleBottom = card.maxY - SourceCardLayout.bottomInset - placeH - SourceCardLayout.rowGap - timeH - SourceCardLayout.rowsTopGap

        let titleText = InviteCardTitle.text(name: vm.profile.name)
        let titleSize = (titleText as NSString).size(withAttributes: [.font: UIFont.title(26, .bold)])
        let titleRect = CGRect(x: left, y: titleBottom - titleSize.height,
                               width: min(titleSize.width, card.width - inset * 2), height: titleSize.height)

        let type = inviteSummary.type
        let emojiW = (type.emoji as NSString).size(withAttributes: [.font: UIFont.body(13, .medium)]).width
        let labelW = (type.longTitle as NSString).size(withAttributes: [.font: UIFont.body(13, .bold)]).width
        let chipW = SourceCardLayout.chipLeadingPad + emojiW + SourceCardLayout.chipInnerGap + labelW + SourceCardLayout.chipTrailingPad
        let chipRect = CGRect(x: card.maxX - inset - chipW,
                              y: titleRect.minY + SourceCardLayout.chipOffsetY,
                              width: chipW, height: SourceCardLayout.chipHeight)

        return SourceAnchors(timeCenter: CGPoint(x: left, y: timeCenterY),
                             placeCenter: CGPoint(x: left, y: placeCenterY),
                             titleRect: titleRect,
                             chipRect: chipRect)
    }

    //The title's landing rect on the carousel image, derived from the frozen flight target +
    //the accept title's own constants (inset, bottom inset, 22pt font at its answering scale)
    private func destTitleRect() -> CGRect {
        let target = carouselTargetFrame
        let text = InviteCardTitle.text(name: vm.profile.name)
        let size = (text as NSString).size(withAttributes: [.font: UIFont.title(22)])
        let scale = InviteImageCarousel.answeringTitleScale
        let scaled = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(x: target.minX + InviteImageCarousel.titleInset,
                      y: target.maxY - InviteImageCarousel.titleBottomInset - scaled.height,
                      width: scaled.width, height: scaled.height)
    }

    //The title flies exactly like the meet card's name hero: one Text laid out at the card's
    //26pt, rect-lerped and height-scaled to the accept title's slot. White at both ends.
    @ViewBuilder
    private func titleHeroLayer(_ origin: CGPoint) -> some View {
        if rowsHeroActive {
            let source = sourceAnchors(in: sourceFrame).titleRect
            let dest = destTitleRect()
            let rect = local(lerp(dest, source, closeP), origin)
            Text(InviteCardTitle.text(name: vm.profile.name))
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .fixedSize()
                .scaleEffect(rect.height / max(source.height, 1), anchor: .center)
                .position(x: rect.midX, y: rect.midY)
                .allowsHitTesting(false)
        }
    }

    //The chip ("🍻 Grab Drinks", white capsule) morphs into the popup's type row (drawn icon +
    //dark 19pt text): both replicas fly one anchor path, size-matched by the text height
    //ratio, crossfading on the flight scalar — the words themselves are identical.
    @ViewBuilder
    private func typeHeroLayer(_ origin: CGPoint) -> some View {
        if rowsHeroActive {
            let anchors = sourceAnchors(in: sourceFrame)
            rowHeroLayer(origin,
                         source: CGPoint(x: anchors.chipRect.minX, y: anchors.chipRect.midY),
                         dest: typeRowDest,
                         landedScale: UIFont.body(19, .medium).lineHeight / max(UIFont.body(13, .bold).lineHeight, 1),
                         cardRow: { typeChipReplica },
                         popupRow: { typeRowReplica })
        }
    }

    @ViewBuilder
    private func timeHeroLayer(_ origin: CGPoint) -> some View {
        if rowsHeroActive {
            rowHeroLayer(origin,
                         source: sourceAnchors(in: sourceFrame).timeCenter,
                         dest: timeRowDest,
                         landedScale: rowHeroScale,
                         cardRow: { timeRowReplica(card: true) },
                         popupRow: { timeRowReplica(card: false) })
        }
    }

    @ViewBuilder
    private func placeHeroLayer(_ origin: CGPoint) -> some View {
        if rowsHeroActive {
            rowHeroLayer(origin,
                         source: sourceAnchors(in: sourceFrame).placeCenter,
                         dest: placeRowDest,
                         landedScale: rowHeroScale,
                         cardRow: { placeRowReplica(card: true) },
                         popupRow: { placeRowReplica(card: false) })
        }
    }

    //The envelope's own hero: the 42pt circle widens into the Accept capsule (the two share
    //the card's 24pt trailing inset, so the morph reads as a pure leftward stretch plus a
    //12pt drop). The FLYING body is a flat capsule — a glass lens rebuilt at a new size every
    //frame drops the device to ~15fps (the card surface's rule) — with the real fixed-size
    //lens riding the trailing cap and fading on closeP, so both resting endpoints are the
    //true glass. The "Accept" text pops on its own blur-pop clock, in at launch, out at
    //close start.
    @ViewBuilder
    private func ctaHeroLayer(_ origin: CGPoint) -> some View {
        if rowsHeroActive {
            let source = sourceEnvelopeRect(in: sourceFrame)
            let dest = acceptDest.width > 1 ? acceptDest : source //First frames only, as the rows
            let rect = local(lerp(dest, source, closeP), origin)
            ZStack {
                Capsule()
                    .fill(acceptIsActive ? Color.textAccent : Color.fillGray) //The real button's resting fill
                Capsule()
                    .fill(Color.accent) //The envelope's tint, shed over the flight
                    .opacity(Double(closeP))
                Text(acceptText)
                    .font(acceptFont)
                    .foregroundStyle(Color.white)
                    .lineLimit(acceptLineLimit)
                    .multilineTextAlignment(.center)
                    .blurPop(visible: expanded)
                    .animation(.transition, value: expanded) //Leaf-side, under the flight transforms — can't swallow the flight's transaction
            }
            .frame(width: rect.width, height: rect.height)
            .overlay(alignment: .trailing) {
                //The resting envelope itself (fixed 42pt — glass may move, never resize),
                //carrying its own letter icon out with it
                InviteButton(onTap: { })
                    .opacity(Double(closeP))
            }
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
        }
    }

    private func sourceEnvelopeRect(in card: CGRect) -> CGRect {
        let size = SourceCardLayout.envelopeSize
        return CGRect(x: card.maxX - SourceCardLayout.contentInset - size,
                      y: card.maxY - SourceCardLayout.bottomInset - size + SourceCardLayout.envelopeOffsetY,
                      width: size, height: size)
    }

    //The card rows are 20pt medium, the popup's 19pt — the replicas size-match on the ratio so
    //the crossfade reads as one line restyling, never two sizes double-exposed
    private var rowHeroScale: CGFloat {
        UIFont.body(19, .medium).lineHeight / max(UIFont.body(20, .medium).lineHeight, 1)
    }

    //One flying row: both stylings always mounted, leading-anchored on a lerped anchor
    //(leading edge at x, centred on y via the zero-size frame), each render-scaled so their
    //text heights coincide at every point of the flight, crossfaded on closeP. Everything is
    //linear in closeP, so the open/close springs and the gesture driver all scrub it.
    private func rowHeroLayer<CardRow: View, PopupRow: View>(
        _ origin: CGPoint,
        source: CGPoint,
        dest: CGRect,
        landedScale: CGFloat,
        @ViewBuilder cardRow: () -> CardRow,
        @ViewBuilder popupRow: () -> PopupRow
    ) -> some View {
        //First frames only: until the destination row reports, the hero holds the card
        let destAnchor = dest.width > 1 ? CGPoint(x: dest.minX, y: dest.midY) : source
        let anchor = local(CGPoint(x: lerp(destAnchor.x, source.x, closeP),
                                   y: lerp(destAnchor.y, source.y, closeP)), origin)
        let t = 1 - closeP //0 at the card, 1 landed
        return ZStack(alignment: .leading) {
            cardRow()
                .scaleEffect(lerp(1, landedScale, t), anchor: .leading)
                .opacity(Double(closeP))
            popupRow()
                .scaleEffect(lerp(1 / max(landedScale, 0.01), 1, t), anchor: .leading)
                .opacity(Double(1 - closeP))
        }
        .frame(width: 0, height: 0, alignment: .leading) //Zero-size anchor: content flows trailing-ward, vertically centred
        .position(x: anchor.x, y: anchor.y)
        .allowsHitTesting(false)
    }

    //MARK: Replicas — pixel-faithful copies of both endpoints' rows

    private var typeChipReplica: some View {
        let type = inviteSummary.type
        return HStack(alignment: .center, spacing: SourceCardLayout.chipInnerGap) {
            Text(type.emoji)
                .font(.body(13))
            Text(type.longTitle)
                .font(.body(13, .bold))
        }
        .foregroundStyle(Color.white)
        .frame(height: SourceCardLayout.chipHeight)
        .padding(.trailing, SourceCardLayout.chipTrailingPad)
        .padding(.leading, SourceCardLayout.chipLeadingPad)
        .capsuleStroke(lineWidth: 1, color: .white)
        .lineLimit(1)
        .fixedSize()
    }

    private var typeRowReplica: some View {
        HStack(spacing: Spacing.sm) {
            Image(.drinkIconDark)
                .renderingMode(.original)
                .frame(width: 20, alignment: .leading) //Geometry: icon column both rows align to
            Text(inviteSummary.type.longTitle)
        }
        .font(.body(19, .medium))
        .foregroundStyle(Color.textPrimary)
        .lineLimit(1)
        .fixedSize()
    }

    private func timeRowReplica(card: Bool) -> some View {
        HStack {
            HStack(spacing: card ? Spacing.xs : Spacing.sm) {
                Image(card ? .whiteClock : .eventClockIcon)
                    .renderingMode(card ? .template : .original)
                    .frame(width: 20, alignment: .leading) //Geometry: icon column both rows align to
                Text(DynamicTimeRow.text(for: vm.respondDraft))
            }
            .padding(.top, -1)
            Image(systemName: "chevron.right")
                .font(.body(12, .bold))
                .offset(y: -2)
        }
        .font(.body(card ? 20 : 19, .medium))
        .kerning(0.1)
        .foregroundStyle(card ? cardPalette.secondaryText : Color.textPrimary)
        .animation(.transition, value: cardPalette) //Extraction lands a frame late — the tint fades in rather than snaps (leaf-side, can't swallow the flight's transaction)
        .lineLimit(1)
        .fixedSize()
    }

    private func placeRowReplica(card: Bool) -> some View {
        let place = inviteSummary.place
        return HStack(spacing: card ? Spacing.xs : Spacing.sm) {
            Image(card ? .whiteMap : .eventMapIcon)
                .renderingMode(card ? .template : .original)
                .frame(width: 20, alignment: .leading) //Geometry: icon column both rows align to
            Text(place.name ?? place.address ?? "View on map")
        }
        .font(.body(card ? 20 : 19, .medium))
        .kerning(0.1)
        .foregroundStyle(card ? cardPalette.secondaryText : Color.textPrimary)
        .animation(.transition, value: cardPalette) //As the time row: the tint's late arrival fades in
        .lineLimit(1)
        .fixedSize()
    }

    //Guarded like every other frame here: the destination anchors are the heroes' landing
    //pads, frozen while the finger or the flight driver owns the geometry
    private func destAnchorBinding(_ storage: Binding<CGRect>) -> Binding<CGRect> {
        Binding(
            get: { storage.wrappedValue },
            set: { rect in
                guard !dragging, gestureFlight == nil else { return }
                if rect != storage.wrappedValue { storage.wrappedValue = rect }
            }
        )
    }
}

//MARK: Open/close state machine — SendInviteContainer's, with the hero hand-offs

extension RespondInviteContainer {

    private func openWhenMeasured() {
        guard !hasOpened, imageFrame.height > 50, cardFrame.height > 50 else { return }
        hasOpened = true
        guard hasFlight else { //No source (a direct mount): present complete on the first laid-out frame, as before
            expanded = true
            landed = true
            rowsLanded = true
            chromeIn = true
            chevronIn = true
            pagerReveal = 1
            coversDropped = true
            closeP = 0
            coverFade = 0
            return
        }
        heroesEngaged = carouselScreen == .accept //A persisted new-event draft has no rows for the heroes to land on
        flightTargets = (cardFrame, imageFrame) //Freeze the destination for this flight
        let generation = flightGeneration
        Task { @MainActor in //One committed frame at the source rect before the flight animates from it
            sourceChromeExiting = true //The envelope pops away on its own clock
            withAnimation(SendInviteContainer.sourceChromeExit) { sourceChromeFade = 0 }
            chromeIn = true //The chrome LEADS the flight, as on the send card
            withAnimation(SendInviteContainer.openFlight, completionCriteria: .removed) {
                expanded = true
                closeP = 0
            } completion: {
                land(generation)
            }
            scheduleChevronIn(generation)
        }
    }

    private func scheduleChevronIn(_ generation: Int) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(SendInviteContainer.openSpring.duration * SendInviteContainer.chevronInShare))
            guard expanded, generation == flightGeneration else { return }
            chevronIn = true
        }
    }

    private func expandedChanged(_ isExpanded: Bool) {
        if isExpanded {
            guard hasFlight else { return } //A no-flight mount landed inline in openWhenMeasured
            dragging = false
            springingBack = false
            coverFade = 1 //Cover the pager until this flight lands (identical pixels — instant is invisible)
            let generation = flightGeneration
            Task {
                //Redundant with the flight completion, in case it never fires — well past the
                //spring's settling tail (see SendInviteContainer.expandedChanged)
                try? await Task.sleep(for: .seconds(1.0))
                land(generation)
            }
        } else {
            flightGeneration += 1
            landed = false
            chromeIn = false //Chrome pops out at close start, ahead of the flight home
            chevronIn = false
            pagerReveal = 0
            coversDropped = false
            rowsLanded = false //The heroes take the words back for the flight home
        }
    }

    private func land(_ generation: Int) {
        guard expanded, !landed, generation == flightGeneration else { return }
        landed = true
        chromeIn = true //Normally already in on its own clock — this covers the fallback land
        chevronIn = true
        flightTargets = nil //Live measurements own the geometry again
        blurCover = 0
        Task { @MainActor in //The row swap waits out the spring's last sub-pixel settle (the name hero's rule)
            try? await Task.sleep(for: .seconds(0.15))
            guard expanded, generation == flightGeneration else { return }
            rowsLanded = true
        }
        if let coverPage, images.indices.contains(coverPage) { //A reopen mid-close: give the pager its page back
            snapPager { $0.scrollTo(id: images[coverPage], anchor: .leading) }
        }
        if coverPage != nil {
            //Reopen mid-close from a non-hero page: keep the pre-reveal cut (see SendInviteContainer.land)
            pagerReveal = 1
            coversDropped = true
            coverPage = nil
            withAnimation(.transition) { coverFade = 0 }
            return
        }
        withAnimation(.transition, completionCriteria: .removed) { pagerReveal = 1 } completion: {
            guard expanded, generation == flightGeneration else { return }
            coversDropped = true
            coverPage = nil
            withAnimation(.transition) { coverFade = 0 }
        }
    }

    private func closeInvite() {
        guard hasFlight else { //No source to collapse into: unmount as before
            showInvite = false
            return
        }
        prepareClose()
        expanded = false //Chrome fades out on its own .transition scopes; hit gates drop
        launchCloseFlight()
    }

    //The TAP close: one clock — mask and image collapse together on the settle spring; the
    //handback fires at the spring's perceptual rest (see SendInviteContainer.launchCloseFlight)
    private func launchCloseFlight() {
        Task { @MainActor in
            withAnimation(SendInviteContainer.chromeRace) { blurCover = 0 }
            withAnimation(.interpolatingSpring(SendInviteContainer.settleFlight, initialVelocity: 0), completionCriteria: .logicallyComplete) {
                closeP = 1
                chromeRaceP = 1
            } completion: {
                guard !expanded else { return } //A reopen mid-close owns the card now
                showInvite = false
            }
        }
    }

    private func reopen() {
        stopGestureFlight()
        heroesEngaged = carouselScreen == .accept
        sourceChromeExiting = true
        withAnimation(SendInviteContainer.sourceChromeExit) { sourceChromeFade = 0 }
        chromeIn = true
        withAnimation(SendInviteContainer.chromeRace) { blurCover = 0 }
        withAnimation(SendInviteContainer.openFlight) {
            expanded = true
            closeP = 0
            chromeRaceP = 0
            cropScrub = 0
        }
        scheduleChevronIn(flightGeneration)
    }

    private func prepareClose() {
        flightTargets = (cardFrame, imageFrame) //Freeze the collapse's from-geometry
        //No visible rows to leave from — a new-event screen, or the rows pager scrolled to the
        //message page (the anchors would launch heroes from off-screen) — hands the words to
        //the chrome copy's chromeFade ride instead
        heroesEngaged = carouselScreen == .accept && rowsAtRest
        sourceChromeFade = 1 //The cap steps aside: the chrome copy rides the collapse back in via closeP
        sourceChromeExiting = false //The envelope pops back, revealed by the collapse
        blurCover = coversDropped ? 1 : 0
        //Resting on the hero page with a sharp bottom: the hero cover is identical pixels. A
        //blurred page (new-invite compose) routes through the snapshot even on page 0 — the
        //hero cover is raw pixels, and swapping it under the glur'd pager pops the blur off in
        //one frame instead of the race's fade.
        guard scrollProgress > 0.001 || carouselScreen.blursBottom else {
            coverFade = 1
            return
        }
        coverPage = currentPage //Freeze the visible page over the live pager…
        snapPager { $0.scrollTo(edge: .leading) } //…so the pager is home before it unmounts
        withAnimation(SendInviteContainer.closeFlight) { coverFade = 1 }
    }

    //The measured time-row anchor sits at the rows page's resting leading edge only while the
    //inner rows↔message pager is home; scrolled away, the live anchors ride off-card
    private var rowsAtRest: Bool {
        abs(timeRowDest.minX - (cardFrame.minX + SourceCardLayout.contentInset)) < 4
    }

    private var currentPage: Int {
        min(max(Int(scrollProgress.rounded()), 0), images.count - 1)
    }

    private func snapPager(_ move: (inout ScrollPosition) -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { move(&pagerPosition) }
    }
}

//MARK: Interactive dismiss — SendInviteContainer's ported profile machine, on this card.
//Every constant and curve comes from DragTuning / InviteDragTuning; only the hosting state
//differs. See the MARK in SendInviteContainer for the full reasoning.
extension RespondInviteContainer {

    private func dismissDrag(_ origin: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if dragAxis == nil {
                    let vertical = abs(value.translation.height) >= abs(value.translation.width)
                    let canBegin = hasFlight && expanded && landed && !springingBack && !timeAndPlaceUI.isPopupOpen()
                        && !startsOnActionMenu(value.startLocation, origin)
                    if vertical, catchCancelSpring() {
                        dragAxis = .vertical
                        dragStart = slopOrigin(value.translation)
                    } else if vertical && canBegin {
                        dragAxis = .vertical
                        beginDrag()
                        dragStart = slopOrigin(value.translation)
                    } else {
                        dragAxis = .horizontal //Voided for this touch: horizontals belong to the pager, button touches to the buttons
                    }
                }
                guard dragAxis == .vertical, dragging, expanded else { return }
                (dragProgress, dragOffset) = dragModel(for: adjusted(value.translation))
            }
            .onEnded { value in
                let owned = dragAxis == .vertical && dragging
                dragAxis = nil
                guard owned, expanded else { return }
                let t = adjusted(value.translation)
                let flick = DragTuning.projectedTravel(value.velocity.height)
                if dragProgress > InviteDragTuning.dismissThreshold
                    || (t.height > 20 && flick > InviteDragTuning.flickFloor) {
                    dragging = false //The flight owns the card now
                    routeRelease(translation: t, velocity: value.velocity)
                } else {
                    cancelDrag(velocity: value.velocity)
                }
            }
    }

    private func adjusted(_ translation: CGSize) -> CGSize {
        CGSize(width: translation.width - dragStart.width,
               height: translation.height - dragStart.height)
    }

    //Zero ONLY the 12pt recognition slop, never the excess (see SendInviteContainer.slopOrigin)
    private func slopOrigin(_ t: CGSize) -> CGSize {
        let m = max((t.width * t.width + t.height * t.height).squareRoot(), 0.001)
        let s = min(m, 12) / m
        return CGSize(width: t.width * s, height: t.height * s)
    }

    //The decline/accept row owns every touch that lands on it — pressing a button and sliding
    //off it must not scrub the card away under the finger. Touch-DOWN point only.
    private func startsOnActionMenu(_ start: CGPoint, _ origin: CGPoint) -> Bool {
        local(actionMenuHitArea, origin).contains(start)
    }

    private func beginDrag() {
        dragging = true
        snapPager { $0.scrollTo(id: images[currentPage], anchor: .leading) } //Kill an in-flight flick; frames are frozen from here
    }

    private func dragModel(for t: CGSize) -> (progress: CGFloat, offset: CGSize) {
        var (progress, offset) = ghostModel(for: t)
        if let base = regrabProgress {
            let w = min(1, (abs(t.width) + abs(t.height)) / 120)
            progress = lerp(base, progress, w)
            offset = CGSize(width: lerp(regrabOffset.width, offset.width, w),
                            height: lerp(regrabOffset.height, offset.height, w))
            if w >= 1 { regrabProgress = nil }
        }
        return (progress, offset)
    }

    private func ghostModel(for t: CGSize) -> (progress: CGFloat, offset: CGSize) {
        let progress = min(max(t.height / InviteDragTuning.collapseDistance, 0), 1)
        let offset = CGSize(
            width: DragTuning.rubberBand(t.width, limit: 160, response: 0.8),
            height: t.height >= 0
                ? DragTuning.rubberBand(t.height, limit: 700, response: 1)
                : DragTuning.rubberBand(t.height, limit: 80, response: 0.9)) //Upward fights back hard
        return (progress, offset)
    }

    //MARK: Release routing — the profile's finishDismiss, verbatim structure

    private func routeRelease(translation t: CGSize, velocity v: CGSize) {
        prepareClose()
        expanded = false
        Task { @MainActor in //One committed frame with the covers up, then the glur leaves (as the tap close)
            withAnimation(SendInviteContainer.chromeRace) { blurCover = 0 }
        }
        if sourceFrame.minY < DragTuning.arcCutoffY {
            runArc(translation: t, velocity: v)
        } else if v.height >= DragTuning.fastFlickVelocity {
            let descent = v.height * DragTuning.rubberBandSlope(t.height, limit: 700, response: 1)
            startSpring(duration: DragTuning.closeFlightDuration, zeta: DragTuning.bounceDamping,
                        v0: descentKick(descent, signedDescent: true), race: standardRace())
        } else {
            startSpring(duration: DragTuning.closeFlightDuration, zeta: DragTuning.bounceDamping,
                        v0: normalizedKick(v), race: standardRace())
        }
    }

    //The TWO-BEAT ARC (see SendInviteContainer.runArc — this is the same machine)
    private func runArc(translation t: CGSize, velocity v: CGSize) {
        if v.height < InviteDragTuning.arcSlowMorphCeil {
            startSpring(duration: DragTuning.arcSlowMorphDuration, zeta: DragTuning.bounceDamping,
                        v0: normalizedKick(v),
                        race: DragTuning.arcSlowMorphDuration * DragTuning.arcSlowMorphRaceShare)
            return
        }
        let D = sourceFrame.minY
        let overshootRaw = DragTuning.arcOvershoot(destinationTop: D, velocity: v.height,
                                                   flickFloor: InviteDragTuning.arcFlickFloor,
                                                   flickCeil: InviteDragTuning.arcFlickCeil,
                                                   blendSteep: InviteDragTuning.arcFlickBlendSteep)
        let pivotHeight = targetImageFrame.width
            * (sourceFrame.height / max(sourceFrame.width, 1)) * DragTuning.minDragScale
        let pivotAnchor = max(D, 0)
        let room = UIScreen.main.bounds.height - pivotAnchor - pivotHeight
        let overshoot = min(overshootRaw, max(room, 0))
        let pivotTop = pivotAnchor + overshoot
        let targetVirtual = virtualTravel(forImageTop: pivotTop)
        let delta = targetVirtual - t.height
        let pace = DragTuning.travelPaceBoost(destinationTop: D)
        var settle = DragTuning.arcReturnSettle(velocity: v.height) / TimeInterval(pace.squareRoot())
        guard overshoot > 1, delta > 1 else {
            let deepSettle = DragTuning.throwSettle + DragTuning.aboveScreenTime(destinationTop: D)
            let residual = max(v.height, 0) * DragTuning.rubberBandSlope(t.height, limit: 700, response: 1)
            startSpring(duration: deepSettle, zeta: 1, v0: descentKick(residual), race: standardRace())
            return
        }
        var launch = min(max(v.height * DragTuning.arcPaceScale,
                             DragTuning.arcMinLaunch), DragTuning.arcMaxLaunch) * pace
        var omega = Double(launch) / (M_E * Double(delta))
        var diveDuration = min(1.0 / omega, DragTuning.arcMaxDiveTime)
        let base = DragTuning.arcTimeMin + (DragTuning.arcTimeMax - DragTuning.arcTimeMin)
            * TimeInterval(min(overshoot / DragTuning.arcMaxOvershoot, 1))
        let natural = diveDuration + settle
        if natural > 0.01 {
            let dive = max(diveDuration * (base / natural), base * DragTuning.arcMinDiveShare)
            diveDuration = dive
            settle = (base - dive) + DragTuning.aboveScreenTime(destinationTop: D)
            omega = 1.0 / dive
            launch = CGFloat(M_E * Double(delta) * omega)
        }
        settle += DragTuning.arcFlickFadeTime(velocity: v.height) //Settle-only: the dive is untouched
        var flight = GestureFlight()
        flight.diveDuration = diveDuration
        flight.omega = omega
        flight.origin = t
        flight.launch = CGPoint(x: v.width, y: launch)
        flight.springDuration = settle
        flight.zeta = 1
        flight.raceFrom = max(dragProgress, chromeRaceP)
        flight.total = diveDuration + settle
        startGestureFlight(flight)
    }

    //MARK: Kicks — UIKit's initialVelocity convention, the profile's exact conversions

    private func normalizedKick(_ v: CGSize) -> CGFloat {
        min(max(v.height / InviteDragTuning.collapseDistance, 0), 4)
    }

    private var remainingTravel: CGFloat {
        max(abs(sourceFrame.midY - (targetImageFrame.midY + dragOffset.height)), 1)
    }

    private func descentKick(_ descentSpeed: CGFloat, signedDescent: Bool = false) -> CGFloat {
        var dy = -min(max(descentSpeed / remainingTravel, -4), 4)
        if signedDescent, sourceFrame.midY > targetImageFrame.midY + dragOffset.height {
            dy = -dy //The slot sits BELOW the release pose: downward is toward the target
        }
        return dy
    }

    //Inverts the drag rule (see SendInviteContainer.virtualTravel — pure model math)
    private func virtualTravel(forImageTop screenTop: CGFloat) -> CGFloat {
        let A = targetImageFrame.midY
        let I = targetImageFrame.minY
        func poseTop(_ y: CGFloat) -> CGFloat {
            let p = min(max(y / InviteDragTuning.collapseDistance, 0), 1)
            let k = 1 - (1 - DragTuning.minDragScale) * p
            return A + k * (I - A) + DragTuning.rubberBand(y, limit: 700, response: 1)
        }
        let deepBase = A + DragTuning.minDragScale * (I - A)
        let bandNeeded = min(screenTop - deepBase, 660)
        let bandAtSaturation = DragTuning.rubberBand(InviteDragTuning.collapseDistance, limit: 700, response: 1)
        if bandNeeded >= bandAtSaturation {
            return min(700 * bandNeeded / (700 - bandNeeded), 2400)
        }
        var lo: CGFloat = 0, hi = InviteDragTuning.collapseDistance
        guard poseTop(hi) > screenTop else { return hi }
        for _ in 0..<20 {
            let mid = (lo + hi) / 2
            if poseTop(mid) < screenTop { lo = mid } else { hi = mid }
        }
        return (lo + hi) / 2
    }

    //MARK: The flight driver — closed-form beats, one display link

    private func startSpring(duration: TimeInterval, zeta: CGFloat, v0: CGFloat, race: TimeInterval) {
        var flight = GestureFlight()
        flight.springDuration = duration
        flight.zeta = zeta
        flight.v0 = v0
        flight.raceFrom = max(dragProgress, chromeRaceP)
        flight.raceDuration = race
        flight.total = duration
        startGestureFlight(flight)
    }

    private func standardRace() -> TimeInterval {
        DragTuning.maskRaceDuration * max(TimeInterval(1 - chromeMix), 0.2)
    }

    private func startGestureFlight(_ flight: GestureFlight) {
        var f = flight
        f.fromProgress = dragProgress
        f.fromOffset = dragOffset
        f.start = CACurrentMediaTime()
        gestureFlight = f
        flightLink.start { now in flightTick(now) } //@State setters are nonmutating — safe from the escaping tick
    }

    private func stopGestureFlight() {
        flightLink.stop()
        gestureFlight = nil
    }

    private func flightTick(_ now: CFTimeInterval) {
        guard var flight = gestureFlight else { flightLink.stop(); return }
        let elapsed = max(now - flight.start, 0)

        //Watchdog: a wedged flight must still resolve
        if elapsed > flight.total + 1.0 {
            finishGestureFlight(flight)
            return
        }

        //── Beat 1: the dive (arc flights only) ──
        if flight.diveDuration > 0 {
            let t = min(elapsed, flight.diveDuration)
            let impulse = CGFloat(t * exp(-flight.omega * t))
            let virtual = CGSize(width: flight.origin.width + flight.launch.x * impulse,
                                 height: flight.origin.height + flight.launch.y * impulse)
            let (p, o) = ghostModel(for: virtual)
            dragProgress = p
            dragOffset = o
            let f = CGFloat(min(t / max(flight.diveDuration, 0.001), 1))
            let closing = f * f * (3 - 2 * f)
            chromeRaceP = flight.raceFrom + (1 - flight.raceFrom) * closing
            let cf = CGFloat(min(t / max(flight.diveDuration * 0.8, 0.001), 1))
            cropScrub = cf * cf * (3 - 2 * cf)
            guard elapsed >= flight.diveDuration else { return }
            let slope = exp(-flight.omega * t) * (1 - flight.omega * t)
            let residual = flight.launch.y * CGFloat(slope)
                * DragTuning.rubberBandSlope(virtual.height, limit: 700, response: 1)
            flight.diveDuration = 0 //The spring beat owns the clock from here
            flight.start = now
            flight.v0 = descentKick(residual)
            flight.fromProgress = dragProgress
            flight.fromOffset = dragOffset
            flight.raceFrom = chromeRaceP
            flight.raceDuration = 0
            flight.total = flight.springDuration
            gestureFlight = flight
            return
        }

        //── Beat 2: the spring (settle / collapse / cancel) ──
        let u = springRemaining(t: elapsed, duration: flight.springDuration,
                                zeta: flight.zeta, v0: flight.v0)
        let poseU = max(u, 0)
        dragProgress = flight.fromProgress * poseU
        dragOffset = CGSize(width: flight.fromOffset.width * poseU,
                            height: flight.fromOffset.height * poseU)
        if flight.isCancel {
            //Home is the presented card: closeP stays 0, the backdrop formula tracks the unwind
        } else {
            closeP = 1 - u //Overshoot extrapolates the rect past the slot, as every close here does
            if flight.raceDuration > 0.001 {
                let uR = springRemaining(t: elapsed, duration: flight.raceDuration, zeta: 1, v0: 0)
                let race = 1 - min(max(uR, 0), 1)
                chromeRaceP = flight.raceFrom + (1 - flight.raceFrom) * race
                cropScrub = max(cropScrub, race)
            } else {
                chromeRaceP = 1
            }
        }
        //Done at perceptual rest (see SendInviteContainer.flightTick for the gate's derivation)
        if elapsed >= flight.springDuration, abs(u) < 0.01 || elapsed >= flight.springDuration * 1.5 {
            finishGestureFlight(flight)
        }
    }

    private func finishGestureFlight(_ flight: GestureFlight) {
        stopGestureFlight()
        dragProgress = 0
        dragOffset = .zero
        if flight.isCancel {
            springingBack = false
            guard expanded else { return } //A close started mid-spring; leave state to that flight
            dragging = false
        } else {
            closeP = 1
            chromeRaceP = 1
            guard !expanded else { return } //A reopen mid-close owns the card now
            showInvite = false
        }
    }

    //MARK: Cancel + catch — the profile's cancelDismiss / catchFlight pair

    private func cancelDrag(velocity: CGSize) {
        //A sub-perceptual pose resets on the plain animation path instead of the flight driver
        //(the driver freezes the geometry measurements — see SendInviteContainer.cancelDrag)
        if dragProgress < 0.04, abs(dragOffset.width) < 8, abs(dragOffset.height) < 8 {
            dragging = false
            withAnimation(.transition) {
                dragProgress = 0
                dragOffset = .zero
            }
            return
        }
        springingBack = true
        let v0 = min(max(-velocity.height, 0) / max(abs(dragOffset.height), 1), 8)
        var flight = GestureFlight()
        flight.isCancel = true
        flight.springDuration = DragTuning.openFlightDuration
        flight.zeta = DragTuning.bounceDamping
        flight.v0 = v0
        flight.total = DragTuning.openFlightDuration
        startGestureFlight(flight)
    }

    private func catchCancelSpring() -> Bool {
        guard let flight = gestureFlight, flight.isCancel else { return false }
        stopGestureFlight()
        springingBack = false
        dragging = true
        regrabProgress = dragProgress
        regrabOffset = dragOffset
        return true
    }

    //Closed-form damped spring, normalized (see SendInviteContainer.springRemaining)
    private func springRemaining(t: TimeInterval, duration: TimeInterval,
                                 zeta: CGFloat, v0: CGFloat) -> CGFloat {
        let zw = 6.6 / max(duration, 0.01)
        if zeta >= 0.999 { //Critically damped
            return CGFloat(exp(-zw * t)) * (1 + CGFloat(zw * t) - v0 * CGFloat(t))
        }
        let w = zw / Double(zeta)
        let wd = w * (1 - Double(zeta * zeta)).squareRoot()
        let c2 = (CGFloat(zw) - v0) / CGFloat(wd)
        return CGFloat(exp(-zw * t)) * (cos(CGFloat(wd * t)) + c2 * sin(CGFloat(wd * t)))
    }

    //FROZEN frames, deliberately: the anchor must be flight-invariant
    private func dragAnchor(_ size: CGSize, _ origin: CGPoint) -> UnitPoint {
        guard targetImageFrame.height > 1, size.width > 1, size.height > 1 else { return .center }
        return UnitPoint(x: (targetImageFrame.midX - origin.x) / size.width,
                         y: (targetImageFrame.midY - origin.y) / size.height)
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    private func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
        CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
               width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
    }
}

//The screen's own content — the respond card's pages, buttons and carousel
extension RespondInviteContainer {

    //The image chrome's drag dissolve (see SendInviteContainer.dragChromeFade)
    private var dragChromeFade: Double {
        1 - Double(min(dragProgress / InviteDragTuning.dismissThreshold, 1))
    }

    private var imageSection: some View {
        InviteImageCarousel(
            screen: carouselScreen,
            name: vm.profile.name,
            images: images,
            inviteHasChanges: vm.respondDraft.newEvent.hasChanges,
            isPopupOpen: timeAndPlaceUI.anyPopupOpenDelayed,
            showConfirmScreen: $timeAndPlaceUI.showConfirmScreen,
            showInfoScreen: $timeAndPlaceUI.showInfoScreen,
            responseType: $vm.respondDraft.respondType,
            fillsFrame: true, //The flight frames the carousel; self-sizing would fight the animated rect
            scrollProgress: $scrollProgress,
            pagerPosition: $pagerPosition,
            chromeVisible: chromeIn,
            showsPager: landed, //The heavy pager mounts only at rest, over the held covers…
            pagerFade: pagerReveal, //…and fades in above them
            pagerInteractive: coversDropped && !dragging,
            chromeOpacity: dragChromeFade,
            nameFlying: rowsHeroActive, //The hero text owns the title; the accept line keeps a layout ghost
            declineProfile: {respond(.decline)},
            clearInvite: { withAnimation(.dissolve) { vm.deleteEventDefault() } }
        )
    }

    private var inviteDetailsSection: some View {
        VStack(spacing: 0) {
            ZStack {
                if vm.responseType == .newEvent {
                    newEventPager
                } else {
                    confirmInvitePage
                }
            }
            actionMenu
        }
    }

    private var confirmInvitePage: some View {
        ConfirmContainer(
            event: inviteSummary,
            name: vm.profile.name,
            style: .respondPopup,
            timeOpen: timeAndPlaceUI.delayedTimePopupOpen,
            showMessageSection: ui.hasEventMessage(vm.respondDraft),
            showMessageScreen: $timeAndPlaceUI.showMessageScreen,
            typeRowFrame: destAnchorBinding($typeRowDest),
            placeRowFrame: destAnchorBinding($placeRowDest)) {
                DynamicTimeRow(draft: $vm.respondDraft, timePopupOpen: timeAndPlaceUI.popupBinding(.time), style: .respondPopup)
                    //The time hero's landing pad — reported here because the row is this
                    //container's own closure; guarded like every other frame
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { rect in
                        guard !dragging, gestureFlight == nil else { return }
                        timeRowDest = rect
                    }
            } showInfo: {
                timeAndPlaceUI.showInfoScreen = true
            }
    }

    private var timeAndPlacePage: some View {
        TimeAndPlacePage(ui: timeAndPlaceUI, draft: $vm.respondDraft.newEvent, showMessageScreen: $timeAndPlaceUI.showMessageScreen)
    }

    private var addMessageView: some View {
        //Bind to different message in different context
        AddMessageView(
            message: (vm.responseType == .newEvent) ? $vm.respondDraft.newEvent.message : $vm.respondDraft.respondMessage,
            isRespondMessage: true,
            eventType: $vm.respondDraft.newEvent.type
        )
    }

    //Pages the new event between editing and confirming, mirroring SendInviteContainer.
    private var newEventPager: some View {
        TwoPageScrollView(
            showSecondScreen: $timeAndPlaceUI.showConfirmScreen,
            scrollProgress: .constant(0),
            reflowAnimation: vm.respondDraft.newEvent.hasChanges ? .transition : .dissolve, //An emptied draft is a clear
            screen1: { timeAndPlacePage },
            screen2: { newEventConfirmPage }
        )
        //Worn here, not by either page: pinned to the seam, so a page swap can never
        //slide it off the carousel's bottom edge
        .modifier(InviteSeamWash(tint: palette.secondaryText))
    }

    @ViewBuilder
    private var newEventConfirmPage: some View {
        let showMessageSection: Bool = vm.responseType == .originalInvite && ui.hasEventMessage(vm.respondDraft)


        if let inviteSummary = InviteSummary(draft: vm.respondDraft.newEvent) {
            ConfirmContainer(
                event: inviteSummary,
                name: vm.profile.name,
                style:  .respondPopup,
                timeOpen: timeAndPlaceUI.delayedTimePopupOpen,
                showMessageSection: showMessageSection,
                showMessageScreen: $timeAndPlaceUI.showMessageScreen) {
                    StaticTimeRow(proposedTimes: inviteSummary.time, style: .respondPopup)
                } showInfo:  {
                    timeAndPlaceUI.showInfoScreen = true
                }
        }
    }

    //Gone until the flight lands its chrome, while the FINGER owns the card, and while a
    //popup or the confirm page owns it (SendInviteContainer's chevron rules + this screen's)
    private var backButton: some View {
        let fingerDragging = dragging && gestureFlight == nil
        let hide = timeAndPlaceUI.isPopupOpen() || timeAndPlaceUI.showConfirmScreen == true
        let visible = shown && chevronIn && !fingerDragging && !hide

        return BottomBackButton(visible: visible) { closeInvite() }
            .animation(.transition, value: visible)
    }

    //The chevron's stationary home: the ghost's slot in the landed column, derived from the
    //frozen card frame so it holds position even while the card flies
    @ViewBuilder
    private func stationaryBackButton(_ origin: CGPoint) -> some View {
        if targetCardFrame.height > 1 {
            backButton
                .offset(y: targetCardFrame.maxY - origin.y + Spacing.xl)
        }
    }

    //Defaults left alone deliberately: the .subtle variant is the invite popup family's cache
    //key (warmed by InviteSlot); the card variant re-asks under the card's exact solve so the
    //hero rows lift off wearing the resting card's tint — both are cache hits.
    private func fetchColour() async {
        guard let first = images.first else { return }
        palette = await PopupColorExtractor.shared
            .extractPalette(first, id: vm.profile.id, prominence: .subtle)
        cardPalette = await PopupColorExtractor.shared
            .extractPalette(
                first,
                id: vm.profile.id,
                prominence: .custom(saturation: 0.05, brightness: 1, contrast: 4.5),
                textRegionHeight: BlurAndGradientBackground.inviteRegion,
                cardAspectRatio: AspectRatio.inviteCard.ratio,
                maximumDominantLuminance: 0.15,
                minimumSurfaceChroma: 0.4
            )
    }
}

extension RespondInviteContainer {

    private var actionMenu: some View {

        return HStack(spacing: 18) {
            declineButton
            acceptButton
        }
        //The dismiss drag's stand-down region (startsOnActionMenu), measured INSIDE the
        //margins so the card's side gutters stay plain drag surface. Frozen while the finger
        //or the flight driver owns the card, like every other frame here.
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newFrame in
            guard !dragging, gestureFlight == nil else { return }
            //Geometry: ScoopButton's expandHitArea margin — the buttons take touches that far outside their capsules
            actionMenuHitArea = newFrame.insetBy(dx: -16, dy: -16)
        }
        .padding(.horizontal, Spacing.margin) //Each page owns the gap above this row
    }

    @ViewBuilder
    private var declineButton: some View {
        if vm.responseType != .newEvent {
            Text("Decline")
                .font(.body(18, .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .capsuleStroke(lineWidth: 1, color: .borderStrong)
                .geometryGroup()
                .shrinkPress {respond(.decline)}
        }
    }

    //Shared with the CTA hero, so the flying capsule and the real button can never disagree
    //on fill, words or type. Each response gates on its own requirement: without the .newTime
    //gate the button happily posts an empty ProposedTimes, which wipes the invite's times for
    //both users.
    private var acceptIsActive: Bool {
        switch vm.respondDraft.respondType {
        case .originalInvite: vm.respondDraft.originalInvite.selectedDay != nil
        case .newTime:        !vm.respondDraft.newTime.proposedTimes.dates.isEmpty
        case .newEvent:       vm.respondDraft.newEvent.isComplete
        }
    }

    private var acceptText: String {
        switch vm.respondDraft.respondType {
        case .originalInvite: "Accept"
        case .newTime:        "Propose\nNew Times"
        case .newEvent:       createEventScreen ? "Invite \(vm.profile.name)" : "Send to \(vm.profile.name)"
        }
    }

    private var acceptFont: Font { .body(vm.respondDraft.respondType == .newTime ? 15 : 18, .bold) }
    private var acceptLineLimit: Int { vm.respondDraft.respondType == .newTime ? 2 : 1 }

    private var acceptButton: some View {
        let responseType: ProfileResponse = switch vm.respondDraft.respondType {
        case .originalInvite: .accepted
        case .newTime: .newTime
        case .newEvent: .accepted
        }

        let isDimmed: Bool = timeAndPlaceUI.isPopupOpenDelayed()

        return WideActionButton(text: acceptText, isActive: acceptIsActive, isDimmed: isDimmed, showShadow: false, font: acceptFont, lineLimit: acceptLineLimit) {
            if createEventScreen {
                timeAndPlaceUI.showConfirmScreen = true
            } else {
                respond(responseType)
            }
        }
        .opacity(isDimmed ? 0.4 : 1)
        .allowsHitTesting(!isDimmed)
        .animation(.transition, value: isDimmed)
        //The CTA hero owns this button's pixels for the whole flight — a ghost keeps the layout
        .opacity(rowsHeroActive ? 0 : 1)
        //The hero's landing pad, frozen while the finger or the flight driver owns the geometry
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newFrame in
            guard !dragging, gestureFlight == nil else { return }
            acceptDest = newFrame
        }
    }
}
