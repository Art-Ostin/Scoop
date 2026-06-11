//
//  EventImageView.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct EventImage: View {

    @Bindable var ui: EventUIState
    @Environment(ProfileMorphState.self) private var morph: ProfileMorphState?

    let eventProfile: EventProfile
    let imageSize: CGFloat
    @State var namePosition: CGRect = .zero

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
//            .overlay {
//                BackgroundBlur(image: eventProfile.image ?? UIImage(), size: imageSize, frames: [namePosition], maskCornerRadius: 8)
//            }
//            .overlay(alignment: .bottomLeading) { nameOverlay}
            .coordinateSpace(name: EventImage.cardSpace)
            .onPreferenceChange(EventNameFrameKey.self) {namePosition = $0}
            //The morph flies a copy of this image, so the real one (and its
            //overlays) hides for exactly the frames the copy is on screen.
            .profileMorphSource(id: eventProfile.profile.id, radii: ProfileMorphState.cardRadii)
    }
    
//    private var nameOverlay: some View {
//        Text("Meeting \(eventProfile.profile.name)")
//            .font(.body(24, .bold))
//            .measure(key: EventNameFrameKey.self) { $0.frame(in: .named(EventImage.cardSpace)) }
//            .padding(.vertical)
//            .padding(.horizontal)
//            .foregroundStyle(.white)
//    }
    
    private func openProfile() {
        guard ui.selectedProfile == nil else { return }
        morph?.beginOpen(id: eventProfile.profile.id, image: eventProfile.image)
        ui.selectedProfile = eventProfile.profile
    }
}

extension EventImage {
    fileprivate static let cardSpace = "ProfileCard.card"
}

private struct EventNameFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

/*
 
 */
