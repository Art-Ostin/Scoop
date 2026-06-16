//
//  CustomModifier.swift
//  Scoop
//
//  Created by Art Ostin on 06/12/2025.
//

import SwiftUI



extension View {
    
    
    //3 Applies default colour background and hides scrollIndicator
    func colorBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appCanvas.ignoresSafeArea())
            .scrollIndicators(.never)
    }
    
    //4. HideTabBar when certain condition true
    func hideTabBar(hideBar: Bool = true) -> some View {
        self
            .toolbar(hideBar ? .hidden : .visible, for: .tabBar)
            .tabBarHidden(hideBar) // This is custom Tool bar hidden
    }
    
    //5. Expands the tap area of the view, by adding 16 padding around it, but without affecting the layout
    func expandHitArea(_ inset: CGFloat = 16) -> some View {
        padding(inset)
        .contentShape(.interaction, Rectangle())
        .padding(-inset)
    }
    
    
    //6. Applies class background if availble
    func glassBackgroundIfAvailable< S: InsettableShape>(shape: S) -> some View {
        return Group {
            if #available(iOS 26.0, *) {
                self.glassEffect(in: shape)
            } else {
                self
                    .background(shape.fill(Color.appCanvas))
            }
        }
    }

    //7. Configurable glass effect; falls back to a filled shape pre-iOS 26.
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





