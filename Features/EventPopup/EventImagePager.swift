//
//  EventImage.swift
//  Scoop Test
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

enum InviteScreen {
    //The Five Different Image Screens Possible
    case send, sendConfirm
    case accept, newInvite, newInviteConfirm
    
    //A struct storing all overlay booleans for the view
    struct Overlays {
        var backButton = false
        var options = false
        var toggle = false
        var pageIndicator = false
    }
    
    //For Each view, now declare which overlay visible or not
    var showIcon: Overlays {
        switch self {
        case .send:             Overlays(options: true, pageIndicator: true)
        case .newInvite:        Overlays(options: true, toggle: true, pageIndicator: true)
        case .accept:           Overlays(toggle: true)
        case .sendConfirm:      Overlays(backButton: true)
        case .newInviteConfirm: Overlays(backButton: true)
        }
    }
}


struct EventImagePager: View {

    @Environment(PendingFlightChoreo.self) private var flight: PendingFlightChoreo?
    private var isSettled: Bool { flight?.settled ?? true }
    
    let images: [UIImage]
    
    var body: some View {
        Color.clear
            .aspectRatio(AspectRatio.pendingEvent.ratio, contentMode: .fit)
            .overlay {
                if isSettled {
                    inviteCarousel
                        .scrollDisabled(flight?.dragEngaged ?? false) //An engaged dismiss drag freezes the pager's own axis
                }
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight?.reportPagerBand($0) }
    }
    
    private var inviteCarousel: some View {
        InviteCarousel(
            images: images,
            ratio: AspectRatio.pendingEvent.ratio,
            blursBottom: true,
            scrollProgress: .constant(0))
    }
}
