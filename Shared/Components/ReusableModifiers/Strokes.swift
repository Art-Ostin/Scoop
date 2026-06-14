//
//  Strokes.swift
//  Scoop Test
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

extension View {
    
    func rectangleStroke(radius: CGFloat, lineWidth: CGFloat, color: Color = Color.grayPlaceholder) -> some View {
        self
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(color, lineWidth: lineWidth)
            }
    }
    
    func circleStroke(lineWidth: CGFloat, color: Color = Color.grayPlaceholder) -> some View {
        self
            .overlay {
                Circle()
                    .strokeBorder(color, lineWidth: lineWidth)
            }
    }
}

/*
Example
 .stroke(RoundedRectangle(cornerRadius: 30), linewidth: 1, Color: .appGray)
 */
