//
//  ViewModifiers.swift
//  Scoop
//
//  Created by Art Ostin on 03/12/2025.
//

import SwiftUI
import Glur

private struct AppleImageFadeModifier: ViewModifier {
    let color: Color
    let blurRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(color)
            .glur(
                radius: max(blurRadius, 0),
                offset: 0.46,
                interpolation: 0.34,
                direction: .down,
                noise: 0
            )
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: color.opacity(0), location: 0.50),
                        .init(color: color.opacity(0.60), location: 0.5824),
                        .init(color: color, location: 0.78),
                        .init(color: color, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
    }
}

struct CustomCaption: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body(13, .italic))
            .foregroundStyle(Color.textTertiary)
    }
}

extension View {


    func appleImageFade(to color: Color, blurRadius: CGFloat = 34) -> some View {
        modifier(AppleImageFadeModifier(color: color, blurRadius: blurRadius))
    }

    func customCaption() -> some View {
        modifier(CustomCaption())
    }

    //Applies default colour background and hides scrollIndicator
    func colorBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appCanvas.ignoresSafeArea())
            .scrollIndicators(.never)
    }


    //Expands the tap area of the view, by adding padding around it, but without affecting the layout
    func expandHitArea(_ inset: CGFloat = 16) -> some View {
        padding(inset)
        .contentShape(.interaction, Rectangle())
        .padding(-inset)
    }

    //Clamps content to its measured height (open) or 0 (shut), never removing it; callers animate the flag
    func drawer(isOpen: Bool) -> some View {
        modifier(Drawer(isOpen: isOpen))
    }

    //Configurable glass effect; falls back to a filled shape pre-iOS 26.
    //`tint` colours the glass itself (and becomes the fallback fill) — pass it with
    //an alpha to let more of the backdrop through.
    //Only for a surface with NO glass inside it — see `containerGlassEffect` below.
    @ViewBuilder
    func glassEffectIfAvailable<S: InsettableShape>(clear: Bool = false, interactive: Bool = false, tint: Color? = nil, shape: S) -> some View {
        if #available(iOS 26.0, *) {
            let base: Glass = clear ? .clear : .regular
            let glass: Glass = base.tint(tint)
            self.glassEffect(interactive ? glass.interactive() : glass, in: shape)
        } else {
            self.background(shape.fill(tint ?? Color.appCanvas))
        }
    }

    //Glass for a surface that itself CONTAINS glass — the invite card, whose photo carries the
    //options and back buttons. `.glassEffect` applied to the content pulls every DESCENDANT glass
    //effect into its own glass group: the nested buttons stop drawing their own lens and go
    //near-transparent. Drawing the same glass on a `Color.clear` layer in the background is
    //pixel-identical for the surface but forms its own group, so the children keep their glass.
    //Sim-probed on iOS 26.0 — an options disc over a solid blue photo, mean RGB at its centre:
    //      alone (120,140,200) · inside a `.glassEffect` card (46,93,206) · inside this (120,140,200)
    //and the card's own body reads the same (249,241,232) either way. Siblings of the glassed
    //view were never affected, so a button next to the card (BottomBackButton) needs nothing.
    //`compositingGroup`, a nested `GlassEffectContainer`, an alpha'd tint and an opaque fill over
    //the glass were all probed and none of them break the grouping — only moving the glass does.
    //No `interactive:`: a card-sized lens shouldn't react to touch, and interactive glass on a
    //background layer would swallow the content's taps.
    @ViewBuilder
    //`clipped` strips the material's built-in halo: unclipped .regular glass carries a shadow
    //no API disables, while glass clipped to its own shape sits at the measured no-shadow
    //floor (same lens, same tint). Opt in where a surface must wear ONLY its declared
    //Elevation — the invite card does, so its landing can hand shadows off continuously.
    func containerGlassEffect<S: InsettableShape>(clear: Bool = false, tint: Color? = nil, clipped: Bool = false, shape: S) -> some View {
        if #available(iOS 26.0, *) {
            let base: Glass = clear ? .clear : .regular
            self.background {
                if clipped {
                    Color.clear.glassEffect(base.tint(tint), in: shape).clipShape(shape)
                } else {
                    Color.clear.glassEffect(base.tint(tint), in: shape)
                }
            }
        } else {
            self.background(shape.fill(tint ?? Color.appCanvas))
        }
    }
}

extension View {
    func oneLineLimitAndShrink(minimum: CGFloat = TextShrink.floor) -> some View {
        lineLimitAndShrink(1, minimum: minimum)
    }

    //Shrink-to-fit across n lines — scales down rather than truncating, to the shrink floor.
    //The line limit alone bounds the space, so no height constraint is needed (and a fixed
    //frame would keep n full-size line heights after the text shrank — sim-verified iOS 26).
    func lineLimitAndShrink(_ limit: Int, minimum: CGFloat = TextShrink.floor) -> some View {
        self
            .lineLimit(limit)
            .minimumScaleFactor(minimum)
            .allowsTightening(true)
    }
}

private struct Drawer: ViewModifier {
    let isOpen: Bool

    @State private var height: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true) //Keep every line; the clamp must not compress it
            .getHeight($height)
            .modifier(DrawerRoll(progress: isOpen ? 1 : 0, openHeight: height))
    }
}

//The roll itself. `progress` is the animatable value, so the modifier can tell a roll in flight from a
//settled one — and once settled open it drops the clamp and takes the content's own height instead.
//That is what lets one drawer hold another: a measured height arrives in a single step, never eased,
//so an outer clamp reads its shut size the instant the flag flips and would guillotine the inner
//drawer's still-collapsing content — the section snapping up while the row inside it is mid-animation.
private struct DrawerRoll: Animatable, ViewModifier {
    var progress: CGFloat
    var openHeight: CGFloat //Not animated: the clamp follows the measurement straight up

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    //A roll rides a spring, which overshoots both ends: past 1 the clamp is already gone, and below 0
    //a bare multiply would hand `.frame` a negative height
    private var rollHeight: CGFloat? {
        progress < 1 ? max(openHeight * progress, 0) : nil
    }

    func body(content: Content) -> some View {
        content
            .frame(height: rollHeight, alignment: .top)
            .clipped()
    }
}
