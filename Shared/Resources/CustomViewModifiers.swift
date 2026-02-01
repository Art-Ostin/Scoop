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
            .foregroundStyle(Color.grayText)
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
    
    func defaultShadow() -> some View {
        shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 4)
    }
    
    func containerShadow(
        _ cornerRadius: CGFloat = 24, fill: Color = .background, color: Color = Color.black.opacity(0.22), radius: CGFloat = 6, y: CGFloat = 4) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
            .fill(fill)
            .shadow(color: color, radius: radius, y: y)
        )
    }
    
    func stroke(_ cornerRadius: CGFloat, lineWidth: CGFloat = 1, color: Color) -> some View {
        overlay (
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(color, lineWidth: lineWidth)
        )
    }
    
    func colorBackground(_ color: Color, top: Bool = false) -> some View {
        modifier(BackgroundFill(color: color, top: top))
    }
}



