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

extension View {

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
