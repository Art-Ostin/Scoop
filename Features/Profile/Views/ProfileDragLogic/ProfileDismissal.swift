//
//  ProfileDismissal.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

extension ProfileView {
    
    var activeProfileOffset: CGFloat {
        dismissOffset ?? profileOffset
    }
    
    func dismissProfile(using geo: GeometryProxy, startingOffset: CGFloat? = nil) {
        let distance = geo.size.height + geo.safeAreaInsets.bottom
        if let startingOffset {
            dismissOffset = startingOffset
        }
        withAnimation(.snappy(duration: ui.dismissalDuration)) {
            dismissOffset = distance
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ui.dismissalDuration) {
            selectedProfile = nil
        }
    }
    
    var profileBackground: some View {
        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24) //Bug fix: Critical! Solved the dismissing screen.
            .fill(Color.background)
            .ignoresSafeArea()
            .shadow(color: profileOffset.isZero ? Color.clear : .black.opacity(0.25), radius: 12, y: 6)
    }
}
