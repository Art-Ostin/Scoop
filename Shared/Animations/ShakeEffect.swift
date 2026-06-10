//
//  ShakeEffect.swift
//  Scoop
//
//  Created by Art Ostin on 22/11/2025.
//

import SwiftUI

struct Shake: GeometryEffect {
    var travel: CGFloat = 8
    var shakes: CGFloat = 6
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        
        
        let x = travel * sin(animatableData * .pi * shakes)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}

// MARK: - Default show / dismiss animation

extension Animation {
    /// Scoop's default spring for showing & dismissing UI (info buttons, overlays, etc.).
    static let scoopPop: Animation = .spring(response: 0.35, dampingFraction: 0.7)
}

extension AnyTransition {
    /// Scoop's default appear / disappear transition: a soft blur replace with a slight scale from the top.
    static var scoopPop: AnyTransition {
        AnyTransition(.blurReplace).combined(with: .scale(scale: 0.8, anchor: .top))
    }
}
