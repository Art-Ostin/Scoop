//
//  CornerRadius.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2026.
//

import SwiftUI

enum CornerRadius {

    // Size scale
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    
    
    static let photoCard = xl
    static let thumb = sm
    static let alert: CGFloat = 36 //System .alert panel (measured on iOS 26); its buttons are Capsules

    static func nested(in parent: CGFloat, inset: CGFloat, minimum: CGFloat = 4) -> CGFloat {
        max(parent - inset, minimum)
    }
}

//Standard image clips — continuous corners so curvature matches system chrome
extension View {

    func imageClip(_ radius: CGFloat = CornerRadius.photoCard) -> some View {
        clipShape(.rect(cornerRadius: radius, style: .continuous))
    }

    func imageClip(top: CGFloat, bottom: CGFloat) -> some View {
        clipShape(.rect(
            topLeadingRadius: top,
            bottomLeadingRadius: bottom,
            bottomTrailingRadius: bottom,
            topTrailingRadius: top,
            style: .continuous
        ))
    }
}
