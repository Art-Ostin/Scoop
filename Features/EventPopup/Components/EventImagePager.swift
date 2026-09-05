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

    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    
    @State private var titleRect: CGRect = .zero
    private static let bandSpace = "eventPagerBand"
    
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
            .overlay(alignment: .bottomLeading)  { EventTitle(title: title, textRect: $titleRect, coordSpace: Self.bandSpace) }
//            .overlay(alignment: .bottomTrailing) { pageIndicator(bandVisible: flight?.bandChromeVisible ?? true) }
        
            //To do with the morph
            .onChange(of: title, initial: true) { flight?.reportTitle($1) }
            .onChange(of: titleRect, initial: true) { flight?.reportPagerTitle($1) } //The frost's capsule: the cover poses it as insets from its own foot
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(EventZoomChoreo.cardSpace)) } action: { flight?.reportPagerBand($0) } //Card space: never through the morph's transforms
            .task(id: images) { await prepare() }
            .onChange(of: carouselVisible, initial: true) { if $1 { latch() } }
            .onChange(of: images) { if carouselVisible { latch() } }
            .coordinateSpace(.named(Self.bandSpace))
    }
    
    private var inviteCarousel: some View {
        InviteCarousel(
            images: mounted.isEmpty ? images : mounted,
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
