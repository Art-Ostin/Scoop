//
//  GlassIfAvailable.swift
//  Scoop Test
//
//  Created by Art Ostin on 31/05/2026.
//

import SwiftUI

enum ScoopButtonStyle: Equatable {
    case glass, clearGlass
    // Shadow is a tinted-only concern: glass draws its own (native on iOS 26,
    // replicated via .customGlassShadow on the fallback), so it isn't configurable there.
    case tinted(Color, shadow: Elevation? = .medium)
}

struct ScoopButton<Content: View, S: Shape>: View {

    var style: ScoopButtonStyle = .glass
    let shape: S
    
    var size: ButtonSize? = nil
    var weight: Font.Weight = .heavy

    let action: () -> Void
    @ViewBuilder var label: () -> Content

    var body: some View {
        if case .tinted(let color, let shadow) = style {
            coloredButton(color: color, shadow: shadow)
        } else {
            glassButton()
        }
    }

    @ViewBuilder
    func sizedLabel() -> some View {
        if let size {
            label().buttonSize(size, weight: weight)
        } else {
            label()
        }
    }
}

extension ScoopButton {
    private func glassButton() -> some View {
        Group {
            if #available(iOS 26.0, *) {
                Button(action: action) {
                    sizedLabel()
                        .glassEffect(style == .clearGlass ? .clear.interactive() : .regular.interactive(), in: shape)
                }
            } else {
                Button(action: action) {
                    sizedLabel()
                        .background(shape.fill(.ultraThinMaterial).brightness(0.06))
                        .expandHitArea()
                }
                .growButton(shadowColor: .black)
            }
        }
        .foregroundStyle(Color.black)
    }
    
    @ViewBuilder
    private func coloredButton(color: Color, shadow: Elevation?) -> some View {
        Group {
            if #available(iOS 26.0, *) { //opted-in shadowless tints fall through to the flat fill below
                Button(action: action) {
                    sizedLabel()
                        .glassEffect(.regular.tint(color), in: shape)
                        .contentShape(shape) //Fixes bug keep!
                }
                .shrinkButton(shadow: shadow, shadowColor: color)
            } else {
                Button(action: action) {
                    sizedLabel()
                        .background(shape.fill(color))
                        .expandHitArea()
                }
                .shrinkButton(shadow: shadow, shadowColor: color)
            }
        }
        .foregroundStyle(Color.white)
    }
}


// TEMP: original button background, kept so callers compile. Remove when updating.
extension View {

    func buttonBackground<S: InsettableShape>(_ shape: S, color: Color = .accent) -> some View {
        let base = foregroundStyle(.white)
        return Group {
            if #available(iOS 26.0, *) {
                base.glassEffect(.regular.tint(color), in: shape)
            } else {
                base
                    .background(shape.fill(color))
                    .buttonShadow(.customGlassShadow)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
        .padding(-16)
    }
}
