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
    
    func animateProfileDismissal(using geo: GeometryProxy) {
        let exit = geo.size.height + geo.safeAreaInsets.bottom
        dismissOffset = profileOffset
        profileOffset = 0
        withAnimation(.easeOut(duration: ui.dismissalDuration)) {
            dismissOffset = exit
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ui.dismissalDuration) {
            selectedProfile = nil
        }
    }
}
