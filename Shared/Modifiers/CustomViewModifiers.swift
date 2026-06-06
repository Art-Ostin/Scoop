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

    func stroke<S: ShapeStyle>(_ cornerRadius: CGFloat, lineWidth: CGFloat = 1, color: S) -> some View {
        overlay (
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(color, lineWidth: lineWidth)
        )
    }
    
    func colorBackground(_ color: Color, top: Bool = false) -> some View {
        modifier(BackgroundFill(color: color, top: top))
    }
}


