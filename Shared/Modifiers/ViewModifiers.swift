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
            .foregroundStyle(Color.textTertiary)
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

extension View {

    func customCaption() -> some View {
        modifier(CustomCaption())
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

    //Applies default colour background and hides scrollIndicator
    func colorBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appCanvas.ignoresSafeArea())
            .scrollIndicators(.never)
    }

    //HideTabBar when certain condition true
    func hideTabBar(hideBar: Bool = true) -> some View {
        self
            .toolbar(hideBar ? .hidden : .visible, for: .tabBar)
            .tabBarHidden(hideBar) // This is custom Tool bar hidden
    }

    //Expands the tap area of the view, by adding padding around it, but without affecting the layout
    func expandHitArea(_ inset: CGFloat = 16) -> some View {
        padding(inset)
        .contentShape(.interaction, Rectangle())
        .padding(-inset)
    }

    //Applies glass background if available
    func glassBackgroundIfAvailable< S: InsettableShape>(shape: S, isClear: Bool = false) -> some View {
        return Group {
            if #available(iOS 26.0, *) {
                self.glassEffect(isClear ? .clear : .regular, in: shape)
            } else {
                self
                    .background(shape.fill(Color.appCanvas))
            }
        }
    }

    //Configurable glass effect; falls back to a filled shape pre-iOS 26.
    func glassEffectIfAvailable<S: InsettableShape>(clear: Bool = false, interactive: Bool = false, shape: S) -> some View {
        return Group {
            if #available(iOS 26.0, *) {
                let glass: Glass = clear ? .clear : .regular
                self.glassEffect(interactive ? glass.interactive() : glass, in: shape)
            } else {
                self.background(shape.fill(Color.appCanvas))
            }
        }
    }
}
