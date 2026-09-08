//
//  EventImagePager.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

struct EventImagePager: View {
    
    //Injected
    let images: [UIImage]
    let title: String
    var showsPageDots: Bool = true //Only a page you can swipe carries them — the card owns that call, not the title
    var titleVisible: Bool = true //An open popup takes the band: the card owns that call
    var bandFilled: Bool = false //…and lands on this: fill the band so the lens meets a flat ground, not the photo
    var visiblePhoto: Binding<UIImage?> = .constant(nil) //The page on screen, as drawn — what a hero lifting off this pager flies

    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    
    @State private var titleRect: CGRect = .zero
    private static let bandSpace = "eventPagerBand"

    //Geometry: the ground the time platter lands on — the photo's foot, filled while the platter is up.
    //The platter overlaps the photo by ~22pt, and the lens samples a margin past its own edge, so the
    //surplus shows as a white band above the platter. TUNE THE HEIGHT HERE.
    static let bandFillHeight: CGFloat = 18

    static let bandFillInset: CGFloat = 36

    //Geometry: how long the band waits behind the risen platter before it fades in — ON TOP of the 120ms
    //shared delay in ComposeInviteViewModel. The exit ignores this and always cuts. TUNE THE DELAY HERE.
    //Ceiling is the platter's bloom (widthBloom, a 0.46s spring): past that it fades in on a settled platter.
    static let bandFillDelay: TimeInterval = 0.04
    
    //Local view state
    @State private var scrollProgress: Double = 0
    @State private var prepared: PreparedImages?
    @State private var mounted: [UIImage] = []
    
    private var carouselVisible: Bool { flight?.settled ?? true }
    
    var body: some View {
        Color.clear
            .aspectRatio(AspectRatio.pendingEvent.ratio, contentMode: .fit)
            .overlay {
                if carouselVisible {
                    inviteCarousel
                        .scrollDisabled(flight?.dragEngaged ?? false)
                }
            }
            //The white ground the time platter lands on: the photo would otherwise show through the lens
            //and tint its top edge. Same band, same delayed flag as the title that vacates it.
            .overlay(alignment: .bottom) {
                Color.appCanvas
                    .frame(height: Self.bandFillHeight)
                    .padding(.horizontal, Self.bandFillInset)
                    .opacity(bandFilled ? 1 : 0)
                    //Fades IN behind the platter, but CUTS out: the band must be gone before the platter
                    //uncovers it, so its exit can never be a curve with a tail.
                    .animation(bandFilled ? .transition.delay(Self.bandFillDelay) : nil, value: bandFilled)
            }
            //Hidden, never unmounted: the rect it reports is the name morph's anchor and the frost band's
            .overlay(alignment: .bottomLeading)  {
                EventTitle(title: title, textRect: $titleRect, coordSpace: Self.bandSpace)
                    .blurPop(visible: titleVisible, scale: 1) //Scale 1: a shrunk title would report a moved rect
            }
//            .overlay(alignment: .bottomTrailing) { pageIndicator(bandVisible: flight?.bandChromeVisible ?? true) }
        
            //To do with the morph
            .onChange(of: title, initial: true) { flight?.reportTitle($1) }
            .onChange(of: titleRect, initial: true) { flight?.reportPagerTitle($1) }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(EventZoomChoreo.cardSpace)) } action: { flight?.reportPagerBand($0) }
            .task(id: images) { await prepare() }
            .onChange(of: carouselVisible, initial: true) { if $1 { latch() } }
            .onChange(of: images) { if carouselVisible { latch() } }
            .onChange(of: drawnPage, initial: true) { visiblePhoto.wrappedValue = $1 }
            .coordinateSpace(.named(Self.bandSpace))
    }
    
    //What the carousel draws: the decoded copies once latched, the raw images until then
    private var drawn: [UIImage] { mounted.isEmpty ? images : mounted }

    //The page on screen, from the array the carousel actually draws, so a hero lifting off it never
    //pays a first-frame decode. Progress is in pages — `.paging` rests it on an integer
    private var drawnPage: UIImage? {
        guard !drawn.isEmpty else { return nil }
        return drawn[min(max(Int(scrollProgress.rounded()), 0), drawn.count - 1)]
    }

    private var inviteCarousel: some View {
        InviteCarousel(
            images: drawn,
            ratio: AspectRatio.pendingEvent.ratio,
            blurRect: titleRect,
            scrollProgress: $scrollProgress)
    }
    
    private func pageIndicator(bandVisible: Bool) -> some View {
        EventImagePagerIndicator(progress: scrollProgress)
            .eventZoomBandChrome(visible: showsPageDots && bandVisible)
            .offset(y: -4)
    }
}

//For the flight
extension EventImagePager {

    private struct PreparedImages {
        let source: [UIImage] //The array these were decoded from — a stale set is never used for a newer one
        let decoded: [UIImage]
    }

    private func prepare() async {
        let source = images
        let decoded = await withTaskGroup(of: (Int, UIImage).self) { group in
            for (index, image) in source.enumerated() {
                group.addTask {
                    let decoded = await image.byPreparingForDisplay() ?? image
                    return (index, decoded)
                }
            }
            var out = source
            for await (index, image) in group { out[index] = image }
            return out
        }
        guard !Task.isCancelled else { return }
        prepared = PreparedImages(source: source, decoded: decoded)
    }

    private func latch() {
        let decoded = prepared.flatMap { $0.source == images ? $0.decoded : nil }
        let ready = decoded ?? images
        mounted = ready.isEmpty ? [flight?.coverPhoto].compactMap { $0 } : ready
    }
}
