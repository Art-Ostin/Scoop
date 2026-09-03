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

    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    
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
            .overlay(alignment: .bottomLeading)  { EventTitle(title: title) }
            .overlay(alignment: .bottomTrailing) { pageIndicator }
            .onChange(of: title, initial: true) { flight?.reportTitle($1) }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight?.reportPagerBand($0) }
            .task(id: images) { await prepare() }
            .onChange(of: carouselVisible, initial: true) { if $1 { latch() } }
            .onChange(of: images) { if carouselVisible { latch() } }
    }
    
    private var inviteCarousel: some View {
        InviteCarousel(
            images: mounted.isEmpty ? images : mounted,
            ratio: AspectRatio.pendingEvent.ratio,
            blursBottom: true,
            scrollProgress: $scrollProgress)
    }
    
    //Only the compose screens page through the photos
    @ViewBuilder
    private var pageIndicator: some View {
        if title.starts(with: "Invite") {
            EventImagePagerIndicator(progress: scrollProgress).eventZoomBandChrome()
                .offset(y: title.starts(with: "Invite") ? -4 : 0) //Aligns better
        }
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
