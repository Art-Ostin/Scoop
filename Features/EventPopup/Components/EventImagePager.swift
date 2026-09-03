//
//  EventImagePager.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

//The card's image band: a fixed aspect slot the carousel mounts into, with the title (and, when
//composing, the page dots) laid over it. Presented by `.eventZoom`, it reads the flight from the
//environment: the live carousel mounts only once the cover has landed, its axis freezes under
//the dismiss drag, and it reports its band and title so the flying cover can match them. With
//no flight it is a plain pager.
struct EventImagePager: View {
    
    //Injected
    let images: [UIImage]
    let title: String
    var showInfo: (() -> ())?
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo?
    
    //Local view state
    @State private var scrollProgress: Double = 0
    @State private var prepared: PreparedImages? //Display-decoded copies of `images`, off-main — nil until the decode for the CURRENT array lands
    @State private var mounted: [UIImage] = [] //What the carousel shows: latched as it mounts, so a late decode never swaps textures under a visible carousel; re-latched only when `images` itself changes

    var isComposeInvite: Bool { showInfo != nil } //Only show indicators when its compose Invite Mode
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
            .overlay(alignment: .bottomTrailing) { if isComposeInvite { EventImagePagerIndicator(progress: scrollProgress).eventZoomBandChrome() } }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight?.reportPagerBand($0) }
            .onChange(of: EventZoomTitle(text: title, showsInfo: isComposeInvite), initial: true) { flight?.reportTitle($1) }
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
}

//The pre-decode: mounting raw photos blocks main ~150ms while the open spring runs on wall time,
//so the first rendered frame was mid-flight. Decoded during the flight, the pager mounts at land
//on ready textures.
extension EventImagePager {

    private struct PreparedImages {
        let source: [UIImage] //The array these were decoded from — a stale set is never used for a newer one
        let decoded: [UIImage]
    }

    //Concurrent, order preserved: six phone photos in series lose the race to the landing
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

    //Taken as the carousel mounts (or as the pages change under a visible one): the decoded set
    //if it landed for THIS array, else the raw one. A caller that handed the card nothing shows
    //the cover's photo rather than an empty band.
    private func latch() {
        let decoded = prepared.flatMap { $0.source == images ? $0.decoded : nil }
        let ready = decoded ?? images
        mounted = ready.isEmpty ? [flight?.coverPhoto].compactMap { $0 } : ready
    }
}
