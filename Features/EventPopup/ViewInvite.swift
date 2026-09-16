//
//  ViewInvite.swift
//  Scoop
//
//  Created by Art Ostin on 02/09/2026.
//

import SwiftUI

//A sent invite, read-only — card content for `.eventZoom`, which draws the backdrop, the white
//surface and the chevron around it
struct ViewInvite: View {
    let inviteSummary: InviteSummary
    let images: [UIImage]
    let name: String //Needed for Info Section
    let title: String
    
    @State var showInfo = false
    
    var body: some View {
        VStack(spacing: 0) {
            EventImagePager(images: images, title: title)
            Self.details(inviteSummary) { showInfo = true }
        }
        .sheet(isPresented: $showInfo) { Text("Test")}
    }

    ///What the card draws under its photo — one builder, so the View Event flight's copy can never drift from it
    static func details(_ summary: InviteSummary, openInfo: @escaping () -> Void) -> some View {
        EventTypeTimePlace(invite: summary, actionsBelow: false, openInfo: openInfo)
    }
}

//The card as the View Event flight carries it off (`ViewEventFlight`): ViewInvite's own column, its photo band
//left clear for the flight's cover to draw. Inert — the plane it rides takes every touch
struct ViewInviteFlightCopy: View {
    let inviteSummary: InviteSummary

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.aspectRatio(AspectRatio.pendingEvent.ratio, contentMode: .fit) //EventImagePager's band
            ViewInvite.details(inviteSummary) {}
        }
        .background(Color.white) //EventZoomCard's card fill
    }
}
