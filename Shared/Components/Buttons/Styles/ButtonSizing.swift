//
//  DefaultButtons.swift
//  Scoop
//
//  Created by Art Ostin on 02/06/2026.

import SwiftUI

//Good to have consistent button size throughout the app. So (Rounded) Buttons can be one 
enum ButtonSize {
    case small, medium, large

    var fontSize: CGFloat {
        switch self {
        case .small:  15
        case .medium: 16
        case .large:  17
        }
    }
        
    var size: CGFloat {
        switch self {
        case .small:  26
        case .medium: 35
        case .large:  44
        }
    }
}

extension View {
    func buttonSize(_ buttonSize: ButtonSize, weight: Font.Weight = .heavy) -> some View {
        self
            .font(.system(size: buttonSize.fontSize, weight: weight)) //Only applies if systemName font
            .frame(width: buttonSize.size, height: buttonSize.size)
    }
}
