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

    //Configurable glass effect; falls back to a filled shape pre-iOS 26.
    @ViewBuilder
    func glassEffectIfAvailable<S: InsettableShape>(clear: Bool = false, interactive: Bool = false, shape: S) -> some View {
        if #available(iOS 26.0, *) {
            let glass: Glass = clear ? .clear : .regular
            self.glassEffect(interactive ? glass.interactive() : glass, in: shape)
        } else {
            self.background(shape.fill(Color.appCanvas))
        }
    }
}
