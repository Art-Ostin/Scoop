//
//  SendInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

struct SendInviteCard: View {

    static let flight = Animation.smooth(duration: 0.35)

    //Concentric geometry: the image sits `imagePadding` inside the card, so its
    //radius derives from the card's — the corners stay concentric if either changes.
    static let cardRadius: CGFloat = 24 //Uniform card corners; the image top derives from this
    static let screenGap: CGFloat = 10 //Card ↔ screen edge; positions the card, never the image
    static let imagePadding: CGFloat = 3
    static var imageRadius: CGFloat { cardRadius - imagePadding } //Image top corners, concentric with the card
    static let imageBottomRadius: CGFloat = 12 //Image bottom corners — tune freely, nothing nests there
    static let sourceRadius: CGFloat = 20 //Profile card image clip radius (collapsed state)
    static let imageHeightRatio: CGFloat = 1.05
    static let nameBlurInset: CGFloat = 10 //Halo height trim behind "Meet <name>" — raise to shorten
    //Name & dots inset from the image bottom. Shared by the flight chrome and the
    //carousel: the flight glides the text to exactly where the carousel draws it,
    //so if these ever differ the settle handoff snaps.
    static let chromeBottomPadding: CGFloat = 16

    @State var vm: TimeAndPlaceViewModel

    let image: UIImage
    let images: [UIImage] //Full profile gallery for the settled carousel; first ≈ `image`
    let details: String //ProfileCard's info line; the flight chrome fades it out in place
    @Binding var expanded: Bool
    let sourceFrame: CGRect //Profile card image frame, global coords
    let hideInvite: () -> Void
    let sendInvite: (EventFieldsDraft) -> Void

    //Settled layout, measured in global coords from the content below.
    @State private var cardFrame: CGRect = .zero
    @State private var imageFrame: CGRect = .zero
    @State private var hasOpened = false
    //True once the open flight lands; swaps the flight copy for the live carousel.
    @State private var settled = false
    //Measured off the flight chrome's own text so its collapsed layout replicates
    //ProfileCard's overlay exactly (see flightName/flightDetails).
    @State private var meetWidth: CGFloat = 0
    @State private var detailsHeight: CGFloat = 0
    //Name frame in flight-space; anchors the blur halo behind "Meet <name>".
    @State private var flightNameFrame: CGRect = .zero

    var body: some View {
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            ZStack(alignment: .top) {
                cardBackground(origin)
                cardContent(imageWidth: geo.size.width - 2 * (Self.screenGap + Self.imagePadding))
                flightImage(origin)
            }
            .onChange(of: expanded) { _, isExpanded in expandedChanged(isExpanded) }
        }
    }
}

extension SendInviteCard {

    //`imageWidth` derives from the two padding constants, so the image always spans
    //the full card gutter — a fixed frame that's never shrunk to fit the screen height.
    private func cardContent(imageWidth: CGFloat) -> some View {
        VStack(spacing: 0){
            imageSlot(imageWidth)
            sendInviteContainer
        }
        .padding([.horizontal, .top], Self.imagePadding) //Card edge → image: (cardWidth − meet imageSize) / 2
        .padding(.bottom, 12) //With the 8 offset this is 12 in total
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
            cardFrame = $0
            openWhenMeasured()
        }
        .opacity(cardFrame.height > 1 ? 1 : 0) //Nothing shows until measured
        .mask { backgroundShape(cardFrame.origin) } //Revealed by the expanding background
        .allowsHitTesting(expanded)
        .padding(.horizontal, Self.screenGap)
        .padding(.top, 12)
    }

    private func imageSlot(_ width: CGFloat) -> some View {
        Color.clear
            .frame(width: max(width, 0), height: max(width, 0) * Self.imageHeightRatio)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                imageFrame = $0
                openWhenMeasured()
            }
            .overlay { carousel(max(width, 0)) }
    }

    //Sits exactly under the flight copy: page one is the flown image, so the
    //settled swap (flight ↔ carousel) never shows — both flips stay unanimated.
    private func carousel(_ width: CGFloat) -> some View {
        InviteImageCarousel(
            images: images.isEmpty ? [image] : images,
            name: vm.inviteModel.name,
            size: CGSize(width: width, height: width * Self.imageHeightRatio),
            onBack: hideInvite
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
            onClearDraft: {vm.deleteEventDefault()},
            hideInvite: hideInvite,
            onSendInvite: {sendInvite(vm.event)}
        )
    }
}

extension SendInviteCard {

    private func flightImage(_ origin: CGPoint) -> some View {
        let rect = local(expanded ? imageFrame : sourceFrame, origin)
        return Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: rect.width, height: rect.height)
            .clipShape(.rect(
                topLeadingRadius: expanded ? Self.imageRadius : Self.sourceRadius,
                bottomLeadingRadius: expanded ? Self.imageBottomRadius : Self.sourceRadius,
                bottomTrailingRadius: expanded ? Self.imageBottomRadius : Self.sourceRadius,
                topTrailingRadius: expanded ? Self.imageRadius : Self.sourceRadius,
                style: .continuous
            ))
            .overlay { flightBlur(rect.size) }
            .overlay { flightChrome }
            .coordinateSpace(name: Self.flightSpace)
            .position(x: rect.midX, y: rect.midY)
            .opacity(settled ? 0 : 1) //Carousel takes over once landed
            .allowsHitTesting(!settled)
            .onTapGesture {hideInvite()}
    }

    private func cardBackground(_ origin: CGPoint) -> some View {
        backgroundShape(origin)
            //Grows in with the flight; zero while collapsed so only the profile
            //card's own shadow sits under the settled image.
            .shadow(color: .black.opacity(expanded ? 0.05 : 0), radius: 3, x: 0, y: 1)
            .shadow(color: .black.opacity(expanded ? 0.04 : 0), radius: 20, x: 0, y: 0)
    }

    //Shared by the background and the content mask, so rows slide out from
    //exactly under the traveling image.
    private func backgroundShape(_ origin: CGPoint) -> some View {
        let rect = local(expanded ? cardFrame : sourceFrame, origin)
        return RoundedRectangle(cornerRadius: expanded ? Self.cardRadius : Self.sourceRadius, style: .continuous)
            .fill(Color.appCanvas)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }

    private func local(_ rect: CGRect, _ origin: CGPoint) -> CGRect {
        rect.offsetBy(dx: -origin.x, dy: -origin.y)
    }

    //The open flight starts only once BOTH the slot and the card have real frames,
    //and only after the measured collapsed state has committed a rendered frame
    //(pixel-identical over the profile card, so the hold is invisible). Without
    //that the expanding card/mask have no "from" state and snap straight to full
    //size while the image flies. A bare MainActor hop is NOT enough — it still
    //runs before the CA commit — hence the sleep across a real frame boundary
    //(verified frame-by-frame in the simulator).
    private func openWhenMeasured() {
        guard !hasOpened, imageFrame.height > 50, cardFrame.height > 50 else { return }
        hasOpened = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation(sourceFrame.width > 1 ? Self.flight : nil) {
                expanded = true
            } completion: {
                settled = expanded
            }
        }
    }

    //The carousel hides the instant a close starts. A reopen mid-close retargets
    //the spring from MeetContainer (no completion reaches us), so re-settle on a timer.
    private func expandedChanged(_ isExpanded: Bool) {
        if isExpanded {
            Task {
                try? await Task.sleep(for: .seconds(0.4))
                if expanded { settled = true }
            }
        } else {
            settled = false
        }
    }
}

//Text and chrome that ride the flight copy, so everything glides/fades DURING
//the flight: pixel-identical over ProfileCard's overlay when collapsed and over
//the carousel's chrome when settled, making both handoffs invisible.
extension SendInviteCard {

    //ProfileCard's BackgroundBlur treatment behind the name: fades in with the
    //flight and rides beneath the chrome, so the halo glides with the text and
    //hands off pixel-identically to the carousel's always-on copy.
    private func flightBlur(_ size: CGSize) -> some View {
        BackgroundBlur(
            image: image,
            size: size,
            frames: [flightNameFrame],
            clipCornerRadius: Self.imageBottomRadius,
            verticalInset: Self.nameBlurInset
        )
        .opacity(expanded ? 1 : 0)
    }

    private var flightChrome: some View {
        Color.clear
            .overlay(alignment: .bottomLeading) { flightDetails }
            .overlay(alignment: .bottomLeading) { flightName }
            .overlay(alignment: .topLeading) { flightBackButton }
            .overlay(alignment: .bottomTrailing) { flightInviteButton }
            .overlay(alignment: .bottomTrailing) { flightDots }
            .allowsHitTesting(false) //Interaction belongs to the settled carousel
    }

    //The name glides between its two anchors; "Meet " fades in beside it.
    //Collapsed replicates ProfileCard's infoSection: name 16pt from the leading
    //edge, sitting 8pt above the details line, which is 16pt off the bottom.
    private var flightName: some View {
        HStack(spacing: 0) {
            Text("Meet ")
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { meetWidth = $0 }
                .opacity(expanded ? 1 : 0)
            Text(vm.inviteModel.name)
        }
        .font(.title(26))
        .foregroundStyle(Color.white)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.flightSpace)) } action: { flightNameFrame = $0 }
        .padding(.leading, expanded ? SendInviteContainer.contentPadding : 16)
        .padding(.bottom, expanded ? Self.chromeBottomPadding : 16 + detailsHeight + 8)
        .offset(x: expanded ? 0 : -meetWidth) //Collapsed: the bare name sits at the 16pt inset
    }

    private var flightDetails: some View {
        Text(details)
            .font(.body(14, .medium))
            .foregroundStyle(Color.white)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { detailsHeight = $0 }
            .padding(.leading, 16)
            .padding(.bottom, 16)
            .opacity(expanded ? 0 : 1)
            .blur(radius: expanded ? 6 : 0)
    }

    //Always present, never inserted: a view inserted mid-flight renders at the
    //destination geometry, not the interpolated one (verified in the simulator).
    //Scale rides along so the glass reads animated even if its alpha can't fade.
    private var flightBackButton: some View {
        InviteBackButton(action: {})
            .scaleEffect(expanded ? 1 : 0.4)
            .opacity(expanded ? 1 : 0)
    }

    @ViewBuilder
    private var flightDots: some View {
        let count = (images.isEmpty ? [image] : images).count
        if count > 1 {
            AnimatedPageIndicator(count: count, progress: 0)
                .environment(\.colorScheme, .dark)
                .padding(.trailing, 20)
                .padding(.bottom, Self.chromeBottomPadding)
                .opacity(expanded ? 1 : 0)
                .blur(radius: expanded ? 0 : 6)
        }
    }

    //ProfileCard's invite button (dummy morph id — decorative copy), dissolving
    //out as the page dots materialize in the same corner.
    private var flightInviteButton: some View {
        InviteButton(isInviting: true, morphId: "quick-invite-flight-copy", action: {})
            .padding(.trailing, 16)
            .padding(.bottom, 16)
            .opacity(expanded ? 0 : 1)
            .blur(radius: expanded ? 6 : 0)
    }
}

extension SendInviteCard {
    fileprivate static let flightSpace = "SendInviteCard.flight"
}

//One definition, used by the flight copy and the settled carousel, so the
//settle handoff renders it identically.
private struct InviteBackButton: View {
    let action: () -> Void

    var body: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), size: .medium, action: action) {
            Image(systemName: "chevron.left")
        }
        .padding(12)
    }
}

//The settled image: paged profile photos with the name, page dots and a glass
//back button. Lives under the flight copy and takes over once it lands; its
//chrome is always on — the flight copy has already faded it in.
private struct InviteImageCarousel: View {

    let images: [UIImage]
    let name: String
    let size: CGSize
    let onBack: () -> Void

    @State private var scrolledPageID: Int?
    @State private var pageWidth: CGFloat = 0
    @State private var scrollProgress: Double = 0
    @State private var nameFrame: CGRect = .zero

    var body: some View {
        pager
            //Must equal the flight image's expanded radii for the invisible handoff.
            .clipShape(.rect(
                topLeadingRadius: SendInviteCard.imageRadius,
                bottomLeadingRadius: SendInviteCard.imageBottomRadius,
                bottomTrailingRadius: SendInviteCard.imageBottomRadius,
                topTrailingRadius: SendInviteCard.imageRadius,
                style: .continuous
            ))
            .overlay { backgroundBlur }
            .overlay(alignment: .topLeading) { InviteBackButton(action: onBack) }
            .overlay(alignment: .bottomLeading) { nameOverlay }
            .overlay(alignment: .bottomTrailing) { pageDots }
            .coordinateSpace(name: Self.imageSpace)
    }

    //Same halo as ProfileCard, built from whichever page is settled so the
    //backdrop stays true to the visible photo.
    private var backgroundBlur: some View {
        BackgroundBlur(
            image: images[min(scrolledPageID ?? 0, images.count - 1)],
            size: size,
            frames: [nameFrame],
            clipCornerRadius: SendInviteCard.imageBottomRadius,
            verticalInset: SendInviteCard.nameBlurInset
        )
    }

    private var pager: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(images.enumerated()), id: \.offset) { _, page in
                    Image(uiImage: page)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                }
            }
            .scrollTargetLayout()
        }
        .modifier(PagedScrollStyle(
            scrolledPageID: $scrolledPageID,
            pageWidth: $pageWidth,
            scrollProgress: $scrollProgress,
            pageCount: images.count
        ))
    }

    //Two Texts (not one string) so the glyph layout matches the flight's
    //"Meet " + name pair exactly at the handoff.
    private var nameOverlay: some View {
        HStack(spacing: 0) {
            Text("Meet ")
            Text(name)
        }
        .font(.title(26))
        .foregroundStyle(Color.white)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.imageSpace)) } action: { nameFrame = $0 }
        //Leading lines up with the What/When/Where captions below the image
        .padding(.leading, SendInviteContainer.contentPadding)
        .padding(.bottom, SendInviteCard.chromeBottomPadding)
    }

    @ViewBuilder
    private var pageDots: some View {
        if images.count > 1 {
            AnimatedPageIndicator(count: images.count, progress: scrollProgress)
                .environment(\.colorScheme, .dark) //White active dot over the photo
                .padding(.trailing, 20)
                .padding(.bottom, SendInviteCard.chromeBottomPadding) //Level with the name overlay
        }
    }
}

extension InviteImageCarousel {
    fileprivate static let imageSpace = "InviteImageCarousel.image"
}
