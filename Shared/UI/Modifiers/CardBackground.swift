//
//  CardBackground.swift
//  Scoop
//
//  Created by Art Ostin on 21/03/2026.
//

import SwiftUI

struct CardBackground: View {
    var color: Color = .appGreen
    var cornerRadius: CGFloat = 30
    var body: some View {
        ZStack { //Background done like this to fix bugs when popping up
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.background)
                .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 4)
            RoundedRectangle(cornerRadius: cornerRadius)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
        }
    }
}
