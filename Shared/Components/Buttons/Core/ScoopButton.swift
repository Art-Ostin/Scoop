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
    case tinted(Color, shadow: Elevation? = .button, glass: Bool = true)
}

struct ScoopButton<Content: View, S: Shape>: View {

    var style: ScoopButtonStyle = .glass
    let shape: S

    var size: ButtonSize? = nil
    // The pressed look. Tinted-only: the iOS 26 glass path is interactive on its own.
    var press: PressEffect = .shrink

    let action: () -> Void
    @ViewBuilder var label: () -> Content

    //Geometry: tappable margin expanded beyond the visible shape, matching the pre-26 paths.
    private let hitInset: CGFloat = 16

    var body: some View {
        if case .tinted(let color, let shadow, let glass) = style {
            coloredButton(color: color, shadow: shadow, glass: glass)
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

    private func coloredButton(color: Color, shadow: Elevation?, glass: Bool) -> some View {
        Button(action: action) {
            sizedLabel()
                .modifier(ScoopTintSurface(color: color, shape: shape, glass: glass))
                .expandHitArea(hitInset)
        }
        .pressButton(press, shadow: shadow, tint: color)
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

extension View {
    // ScoopButton's glass surface on its own, for a label the system already owns — a Menu's
    // label, say, where nesting a Button would stack the system's control chrome over the glass
    // and wash a `.clear` surface milky. Same look and same pre-26 fallback as ScoopButton.
    func scoopGlassSurface<S: Shape>(clear: Bool = false, shape: S) -> some View {
        modifier(ScoopGlassSurface(clear: clear, shape: shape))
    }
}

// The iOS-26 tinted-glass surface, with a pre-26 flat fill fallback.
private struct ScoopTintSurface<S: Shape>: ViewModifier {
    let color: Color
    let shape: S
    var glass: Bool = true

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    shape.fill(color).opacity(glass ? 0 : 1)
                    glassFill.opacity(glass ? 1 : 0)
                }
            }
            .contentShape(shape) //Fixes interactive-glass hit-shape bug — keep!
    }

    @ViewBuilder
    private var glassFill: some View {
        if #available(iOS 26.0, *) {
            Color.clear.glassEffect(.regular.tint(color), in: shape)
        } else {
            shape.fill(color)
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
