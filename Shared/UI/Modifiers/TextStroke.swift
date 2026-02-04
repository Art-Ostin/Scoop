//
//  TextStroke.swift
//  Scoop
//
//  Created by Art Ostin on 04/02/2026.
//

import SwiftUI

struct GlowBorder: ViewModifier {
    
    var color: Color
    
    var lineWidth:Int
    
    
    func body(content: Content) -> some View {
        applyShadow(content: AnyView(content), lineWidth: lineWidth)
        content
    }
    
    func applyShadow(content: AnyView, lineWidth: Int) -> AnyView {
        if lineWidth == 0 {
            return content
        } else {
            return applyShadow(content: AnyView(content.shadow(color: color, radius: 1)), lineWidth: -1)
        }
    }
}



extension View {
    func glowBoarder(color: Color, lineWidth: Int) -> some View {
        self.modifier(GlowBorder(color: color, lineWidth: lineWidth))
    }
}
