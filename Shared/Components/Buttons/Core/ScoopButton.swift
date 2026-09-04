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
    // `solid`: the tint stays an opaque fill UNDER the lens instead of the lens standing alone —
    // the glass then sheens a solid disc rather than refracting what is behind the button, and a
    // flight can fly a flat capsule of the same colour out of it on identical pixels.
    case tinted(Color, shadow: Elevation? = .button, glass: Bool = true, solid: Bool = false)
}

struct ScoopButton<Content: View, S: Shape>: View {

    var style: ScoopButtonStyle = .glass
    let shape: S

    var size: ButtonSize? = nil
    // The pressed look. Only drives the paths that own their press: the iOS 26 glass path
    // and a tinted button with nativeGlassPress hand theirs to the system instead.
    var press: PressEffect = .shrink
    // Tinted glass only, iOS 26 only: hand the press to Apple's interactive lens
    // (press-and-drag deformation) instead of PressEffect. See coloredButton.
    var nativeGlassPress: Bool = false
    // Tinted glass, layered path only: pin the lens' adaptive look by giving it a hidden backdrop
    // of this colour (see LensWell). Lives INSIDE the press, so the pinned disc scales as one.
    var lensWell: Color? = nil

    let action: () -> Void
    @ViewBuilder var label: () -> Content

    //Geometry: tappable margin expanded beyond the visible shape, matching the pre-26 paths.
    private let hitInset: CGFloat = 16

    var body: some View {
        if case .tinted(let color, let shadow, let glass, let solid) = style {
            coloredButton(color: color, shadow: shadow, glass: glass, solid: solid)
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

    private func coloredButton(color: Color, shadow: Elevation?, glass: Bool, solid: Bool) -> some View {
        // No glass, no lens to press: a flat tinted button keeps PressEffect either way.
        let native = nativeGlassPress && glass
        return Button(action: action) {
            sizedLabel()
                .modifier(ScoopTintSurface(color: color, shape: shape, glass: glass, solid: solid,
                                           interactive: native, well: lensWell))
                .expandHitArea(hitInset)
        }
        .modifier(TintPress(native: native, effect: press, shadow: shadow, tint: color))
        .foregroundStyle(Color.white)
    }
}

// The iOS-26 Liquid Glass surface, with a pre-26 material fallback. No contentShape on the
// glass path: interactive glass overrides any contentShape beneath it. It also clamps the one
// above — sim-measured, expandHitArea buys ~10pt here, not 16 — so don't glass a control that
// needs the full margin to clear 44pt.
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
    var solid: Bool = false //An opaque fill under the lens (see ScoopButtonStyle.tinted)
    // Draws the glass ON the content so the system's press-and-drag lens carries the label
    // with it. Only opt in for a label with no glass of its own — content-applied glass
    // pulls descendant glass into its group.
    var interactive: Bool = false
    var well: Color? = nil //Layered path only: a compositing group above interactive glass would kill its deformation

    func body(content: Content) -> some View {
        // Glass on a Color.clear background layer never gets the system's touch interaction
        // installed at all, so its lens can't deform however it's configured. No contentShape
        // either — same rule as the glass path: expandHitArea above it owns the tap region.
        if #available(iOS 26.0, *), interactive {
            content
                .background { if solid { shape.fill(color) } }
                .glassEffect(.regular.tint(color).interactive(), in: shape)
        } else {
            layeredSurface(content)
        }
    }

    // Both layers stay mounted so a caller can crossfade fill <-> glass without a structural swap.
    private func layeredSurface(_ content: Content) -> some View {
        content
            .background {
                ZStack {
                    shape.fill(color).opacity(glass && !solid ? 0 : 1)
                    glassFill.opacity(glass ? 1 : 0)
                }
            }
            .modifier(LensWell(shape: shape, well: well))
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

// Tinted Liquid Glass is ADAPTIVE: over a dark backdrop the tint renders lit and vivid with a soft
// highlight ring, over a light one deeper with a thin crisp rim — and it averages the backdrop some
// points BEYOND the shape's edge, ignoring fills drawn inside its own layer. A lens over changing
// content (a photo's scrim landing under it, a flying copy leaving that scrim) therefore switches
// look. This pins it: a well of one colour twice the shape's size, rendered WITH the lens as one
// compositing group (the lens then samples the group's own content — the well), masked back to the
// shape so the well never shows. Sim-bisected 2026-09-04: a same-size backing, a masked well without
// the group, and a forced colour scheme all leave the lens adaptive; only group + mask pins it.
// Sits inside the button's press so PressEffect scales the pinned disc whole — outside it, a shrink
// press bared the well as a white ring (device 2026-09-04). Clips any Elevation shadow drawn inside.
private struct LensWell<S: Shape>: ViewModifier {
    let shape: S
    let well: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let well {
            content
                .background { shape.fill(well).scaleEffect(2) } //Backgrounds may overflow the frame
                .compositingGroup()
                .mask { shape }
        } else {
            content
        }
    }
}

// PressEffect and Apple's lens are two press languages: a scale would swamp the native
// squish and re-render the lens at the scaled size, so the native path drops the ButtonStyle.
// The Elevation shadow rides inside PressAnimation, so it is re-applied here or it goes with it.
private struct TintPress: ViewModifier {
    let native: Bool
    let effect: PressEffect
    let shadow: Elevation?
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), native {
            content.shadow(shadow, tint: tint)
        } else {
            content.pressButton(effect, shadow: shadow, tint: tint)
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
