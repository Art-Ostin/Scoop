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
            EventTypeTimePlace(invite: inviteSummary, actionsBelow: false) { showInfo = true}
        }
        .sheet(isPresented: $showInfo) { Text("Test")}
    }
}
