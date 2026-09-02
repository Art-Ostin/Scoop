//
//  ViewInvite.swift
//  Scoop Test
//
//  Created by Art Ostin on 02/09/2026.
//

import SwiftUI

struct ViewInvite: View {

    let inviteSummary: InviteSummary
    let images: [UIImage]
    let name: String //Needed for Info Section
    let title: String
    
    @Binding var showEventScreen: Bool
    @State var showInfo = false
    
    var body: some View {
        ZStack {
            EventBackdropV2()
            VStack(spacing: 60) {
                VStack {
                    EventImagePager(images: images, title: title)
                    EventTypeTimePlace(invite: inviteSummary, actionsBelow: false) { showInfo = true}
                }
                .modifier(EventCardSurfaceV2())
                EventDismissButton { showEventScreen = false }
            }
        }
        .sheet(isPresented: $showInfo) { Text("Test")}
    }
}
