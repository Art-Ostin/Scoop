//
//  NewInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 06/06/2026.
//

import SwiftUI
import Glur


struct InviteCard: View {
    
    //Injected Parameters
    let image: UIImage
    let name: String
    
    @Binding var draft: RespondDraft
    
    let openInvite: () -> ()
    
    //Local Parameters
    @State private var timePopupOpen = false
    
    var body: some View {
        AppImage(image: image, type: .invite)
            .modifier(BlurAndGradientBackground())
            .overlay(alignment: .bottom) {inviteOverlay}
    }
    
    private var inviteOverlay: some View {
        ConfirmContainer(
            event: InviteSummary(event: draft.originalInvite.event),
            name: name,
            isCard: true,
            timeOpen: timePopupOpen,
            showMessageScreen: .constant(false)) {
                DynamicTimeRow(draft: $draft, timePopupOpen: $timePopupOpen)
            } showInfo: {
                //Add scrollTo  code here to scroll to section below.
            }
    }
}


struct BlurAndGradientBackground: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .glur(
                radius: 24,
                offset: 0.7,
                interpolation: 0.34,
                direction: .down,
                noise: 0
            )
            .overlay { blackGradient }
            .clipShape(.rect(cornerRadii: .init(top: 0, bottom: CornerRadius.image)))
    }
    
    private var blackGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0), location: 0.65),
                .init(color: .black.opacity(0.6), location: 0.8),
                .init(color: .black.opacity(0.7), location: 0.85),
                .init(color: .black.opacity(0.9), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}

/*
 InviteCardOverlay(
     name: name,
     timeOpen: timePopupOpen,
     event: InviteSummary(event: draft.originalInvite.event)
 ) {
     DynamicTimeRow(draft: $draft, timePopupOpen: $timePopupOpen)
 } openInvite: {
     openInvite()
 }

 */
