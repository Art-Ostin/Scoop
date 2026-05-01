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
    @State var namePosition: CGRect = .zero
    
    var body: some View {
        Image(uiImage: eventProfile.image ?? UIImage())
            .resizable()
            .defaultImage(imageSize)
            .contentShape(Rectangle())
            .onTapGesture {openProfile()}
            .overlay {backgroundBlur}
            .overlay(alignment: .bottomLeading) { nameOverlay}
            .coordinateSpace(name: EventImageView.cardSpace)
            .onPreferenceChange(EventNameFrameKey.self) {namePosition = $0}
    }
    
    private var nameOverlay: some View {
        Text(eventProfile.profile.name)
            .font(.body(24, .bold))
            .measure(key: EventNameFrameKey.self) { $0.frame(in: .named(EventImageView.cardSpace)) }
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

//Logic dealing with the background Blur
extension EventImageView {
    fileprivate static let cardSpace = "ProfileCard.card"
    
    private var backgroundBlur: some View {
        Image(uiImage: eventProfile.image ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: imageSize, height: imageSize)
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
