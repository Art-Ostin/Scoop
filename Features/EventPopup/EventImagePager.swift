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


/*
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

 */
