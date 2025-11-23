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
