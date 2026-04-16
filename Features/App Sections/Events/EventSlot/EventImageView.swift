//
//  EventImageView.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct EventImageView: View {
    
    @Bindable var ui: EventUIState
    
    let eventProfile: EventProfile
    let imageSize: CGFloat
    
    var body: some View {
        Image(uiImage: eventProfile.image ?? UIImage())
            .resizable()
            .defaultImage(imageSize)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
            .contentShape(Rectangle())
            .onTapGesture {openProfile()}
            .overlay(alignment: .bottomLeading) { nameOverlay}
    }
    
    private var nameOverlay: some View {
        Text(eventProfile.profile.name)
            .font(.body(24, .bold))
            .padding(.vertical)
            .padding(.horizontal)
            .foregroundStyle(.white)
    }
    
    private func openProfile() {
        if ui.selectedProfile == nil {
            ui.dismissOffset = nil
            ui.selectedProfile = eventProfile.profile
        }
    }
}
