//
//  EventImage.swift
//  Scoop Test
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI


struct EventImagePager: View {
    
    //Injected
    let images: [UIImage]
    let title: String
    var showInfo: (() -> ())?
    @Environment(PendingFlightChoreo.self) private var flight: PendingFlightChoreo?
    
    //Local and Computed
    @State private var scrollProgress: Double = 0
    var isComposeInvite: Bool { showInfo != nil } //Only show indicators when its compose Invite Mode
    
    var body: some View {
        Color.clear
            .aspectRatio(AspectRatio.pendingEvent.ratio, contentMode: .fit)
            .overlay {
                if flight?.settled ?? true {
                    inviteCarousel
                        .scrollDisabled(flight?.dragEngaged ?? false)
                }
            }
            .overlay(alignment: .bottomLeading)  { EventTitle(title: title, showInfo: showInfo) }
            .overlay(alignment: .bottomTrailing) { if isComposeInvite { EventImagePagerIndicator(progress: scrollProgress) } }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight?.reportPagerBand($0) }
    }
    
    private var inviteCarousel: some View {
        InviteCarousel(
            images: images,
            ratio: AspectRatio.pendingEvent.ratio,
            blursBottom: true,
            scrollProgress: $scrollProgress)
    }
}
