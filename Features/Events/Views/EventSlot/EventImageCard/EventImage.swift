//
//  EventImageView.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct EventImage: View {

    @Bindable var ui: EventsUIState
    @Environment(ProfileMorphState.self) private var morph: ProfileMorphState?

    let eventProfile: EventProfile
    let imageSize: CGFloat

    var body: some View {
        Image(uiImage: eventProfile.image ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: max(imageSize, 0), height: max(imageSize, 0))
            .clipShape(
                UnevenRoundedRectangle(cornerRadii: ProfileMorphState.cardRadii)
            )
            .contentShape(Rectangle())
            .onTapGesture {openProfile()}
            //The morph flies a copy of this image, so the real one (and its
            //overlays) hides for exactly the frames the copy is on screen.
            .profileMorphSource(id: eventProfile.profile.id, radii: ProfileMorphState.cardRadii)
    }

    private func openProfile() {
        guard ui.selectedProfile == nil else { return }
        morph?.beginOpen(id: eventProfile.profile.id, image: eventProfile.image)
        ui.selectedProfile = eventProfile.profile
    }
}
