//
//  EventImageView.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct EventImage: View {
    
    @Bindable var ui: EventUIState
    
    let eventProfile: EventProfile
    let imageSize: CGFloat
    @State var namePosition: CGRect = .zero
    
    var body: some View {
        Image(uiImage: eventProfile.image ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: max(imageSize, 0), height: max(imageSize, 0))
            .clipShape(
                UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 10, bottomTrailingRadius: 10, topTrailingRadius: 14)
            )
            .contentShape(Rectangle())
            .onTapGesture {openProfile()}
            .overlay {backgroundBlur}
            .overlay(alignment: .bottomLeading) { nameOverlay}
            .coordinateSpace(name: EventImage.cardSpace)
            .onPreferenceChange(EventNameFrameKey.self) {namePosition = $0}
    }
    
    private var nameOverlay: some View {
        Text("Meeting \(eventProfile.profile.name)")
            .font(.body(24, .bold))
            .measure(key: EventNameFrameKey.self) { $0.frame(in: .named(EventImage.cardSpace)) }
            .padding(.vertical)
            .padding(.horizontal)
            .foregroundStyle(.white)
    }
    
    private func openProfile() {
        if ui.selectedProfile == nil {
            ui.selectedProfile = eventProfile.profile
        }
    }
}

//Logic dealing with the background Blur
extension EventImage {
    fileprivate static let cardSpace = "ProfileCard.card"
    
    private var backgroundBlur: some View {
        Image(uiImage: eventProfile.image ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: max(imageSize, 0), height: max(imageSize, 0))
            .blur(radius: 22)
            .mask(nameBlurMask)
            .clipShape(RoundedRectangle(cornerRadius: 22)) //Corner Radius of the card
            .allowsHitTesting(false)
    }
    
    private var nameBlurMask: some View {
        let padX: CGFloat = 4
        let padY: CGFloat = 2
        let feather: CGFloat = 4
        let rect = namePosition.insetBy(dx: -padX, dy: -padY)
        return RoundedRectangle(cornerRadius: 8)
            .frame(width: max(rect.width, 0), height: max(rect.height, 0))
            .position(x: rect.midX, y: rect.midY)
            .blur(radius: feather)
            .opacity(namePosition == .zero ? 0 : 1)
    }
}

private struct EventNameFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
