//
//  ScoopButton.swift
//  Scoop
//
//  Created by Art Ostin on 31/05/2026.
//

import SwiftUI

enum ScoopButtonStyle: Equatable {
    case glass, clearGlass
    // Shadow is a tinted-only concern: glass draws its own (native on iOS 26,
    // replicated via Elevation.glass on the fallback), so it isn't configurable there.
    case tinted(Color, shadow: Elevation? = .button)
}

struct ScoopButton<Content: View, S: Shape>: View {

    var style: ScoopButtonStyle = .glass
    let shape: S

    var size: ButtonSize? = nil

    let action: () -> Void
    @ViewBuilder var label: () -> Content

    //Geometry: tappable margin expanded beyond the visible shape, matching the pre-26 paths.
    private let hitInset: CGFloat = 16

    var body: some View {
        if case .tinted(let color, let shadow) = style {
            coloredButton(color: color, shadow: shadow)
        } else {
            glassButton()
        }
    }

    @ViewBuilder
    private func sizedLabel() -> some View {
        if let size {
            label().buttonSize(size)
        } else {
            label()
        }
    }
}

extension ScoopButton {
    private func glassButton() -> some View {
        Button(action: action) {
            sizedLabel()
                .modifier(ScoopGlassSurface(clear: style == .clearGlass, shape: shape))
                .expandHitArea(hitInset)
        }
        .modifier(GlassFallbackPress())
        .foregroundStyle(Color.textPrimary)
    }

    private func coloredButton(color: Color, shadow: Elevation?) -> some View {
        Button(action: action) {
            sizedLabel()
                .modifier(ScoopTintSurface(color: color, shape: shape))
                .expandHitArea(hitInset)
        }
        .shrinkButton(shadow: shadow, tint: color)
        .foregroundStyle(Color.white)
    }
}

// The iOS-26 Liquid Glass surface, with a pre-26 material fallback. No contentShape
// on the glass path: interactive glass overrides any contentShape beneath it, so the
// tappable area is set by expandHitArea sitting above the glass.
private struct ScoopGlassSurface<S: Shape>: ViewModifier {
    let clear: Bool
    let shape: S
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(clear ? .clear.interactive() : .regular.interactive(), in: shape)
        } else {
            content.background(shape.fill(.ultraThinMaterial).brightness(0.06))
        }
    }
}

// The iOS-26 tinted-glass surface, with a pre-26 flat fill fallback.
private struct ScoopTintSurface<S: Shape>: ViewModifier {
    let color: Color
    let shape: S
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(color), in: shape)
                .contentShape(shape) //Fixes interactive-glass hit-shape bug — keep!
        } else {
            content.background(shape.fill(color))
        }
    }
}

// The grow-on-press feel only exists on the pre-26 glass fallback; iOS 26 glass
// is interactive on its own.
private struct GlassFallbackPress: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            content.growButton(tint: .black)
        }
    }
}


// Glass/tinted background for the map search field. It's applied to a TextField,
// not a Button, so it lives as a standalone modifier rather than folding into ScoopButton.
extension View {

    func buttonBackground<S: InsettableShape>(_ shape: S, color: Color = .accent) -> some View {
        let base = foregroundStyle(.white)
        return Group {
            if #available(iOS 26.0, *) {
                base.glassEffect(.regular.tint(color), in: shape)
            } else {
                base
                    .background(shape.fill(color))
                    .shadow(.glass)
            }
        }
        .expandHitArea()
    }
}
