//
//  ViewModifiers.swift
//  Scoop
//
//  Created by Art Ostin on 03/12/2025.
//

import SwiftUI

struct CustomCaption: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body(13, .italic))
            .foregroundStyle(Color.grayText)
    }
}


struct BackgroundFill: ViewModifier {
    let color: Color
    let top: Bool
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: top ? .top : .center )
            .background(color)
    }
}

enum SurfaceShadowStyle {
    case card
    case floating

    var ambientOpacity: Double {
        switch self {
        case .card: 0.04
        case .floating: 0.06
        }
    }

    var ambientRadius: CGFloat {
        switch self {
        case .card: 8
        case .floating: 10
        }
    }

    var ambientYOffset: CGFloat {
        2
    }

    var keyOpacity: Double {
        switch self {
        case .card: 0.1
        case .floating: 0.14
        }
    }

    var keyRadius: CGFloat {
        switch self {
        case .card: 20
        case .floating: 24
        }
    }

    var keyYOffset: CGFloat {
        switch self {
        case .card: 10
        case .floating: 14
        }
    }
}

private struct SurfaceShadowModifier: ViewModifier {
    let style: SurfaceShadowStyle
    let strength: Double

    func body(content: Content) -> some View {
        let clampedStrength = min(max(strength, 0), 1)

        content
            .shadow(color: .black.opacity(style.ambientOpacity * clampedStrength), radius: style.ambientRadius, x: 0, y: style.ambientYOffset)
            .shadow(color: .black.opacity(style.keyOpacity * clampedStrength), radius: style.keyRadius, x: 0, y: style.keyYOffset)
    }
}

private struct CustomSubtleShadow: ViewModifier {
    let strength: Double

    func body(content: Content) -> some View {
        let clampedStrength = min(max(strength, 0), 1)

        content
            .shadow(color: .black.opacity(0.05 * clampedStrength), radius: 4, x: 0, y: 0)
            .shadow(color: .black.opacity(0.07 * clampedStrength), radius: 6, x: 0, y: 7)
    }
}







extension View {
    
    func customCaption() -> some View {
        modifier(CustomCaption())
    }
    
    func defaultShadow() -> some View {
        shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 4)
    }

    func surfaceShadow(_ style: SurfaceShadowStyle = .card, strength: Double = 1) -> some View {
        modifier(SurfaceShadowModifier(style: style, strength: strength))
    }
    
    func customSubtleShadow(strength: Double = 1) -> some View {
        modifier(CustomSubtleShadow(strength: strength))
    }
    
    func containerShadow(
        _ cornerRadius: CGFloat = 24, fill: Color = .background, color: Color = Color.black.opacity(0.22), radius: CGFloat = 6, y: CGFloat = 4) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
            .fill(fill)
            .shadow(color: color, radius: radius, y: y)
        )
    }
    
    func stroke<S: ShapeStyle>(_ cornerRadius: CGFloat, lineWidth: CGFloat = 1, color: S) -> some View {
        overlay (
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(color, lineWidth: lineWidth)
        )
    }
    
    func colorBackground(_ color: Color, top: Bool = false) -> some View {
        modifier(BackgroundFill(color: color, top: top))
    }
}


