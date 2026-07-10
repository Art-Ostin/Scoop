//
//  ScoopFonts.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

extension Font {
    
    enum bodyFontWeight: String {
        case regular = "ModernEra-Regular"
        case medium = "ModernEra-Medium"
        case bold = "ModernEra-Bold"
        case italic = "ModernEra-MediumItalic"
    }
    
    enum titleFontWeight: String {
        case bold = "SFProRounded-Bold"
        case semibold = "SFProRounded-Semibold"
        case medium = "SFProRounded-Medium"
    }

    static func body(_ size: CGFloat = 16, _ weight: bodyFontWeight = .medium) -> Font {
        .custom(weight.rawValue, size: size)
    }

    static func title(_ size: CGFloat = 32, _ weight: titleFontWeight = .bold) -> Font {
        .custom(weight.rawValue, size: size)
    }
}

extension UIFont {
    static func body(_ size: CGFloat = 16, _ weight: Font.bodyFontWeight = .medium) -> UIFont {
        UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size)
    }

    static func title(_ size: CGFloat = 32, _ weight: Font.titleFontWeight = .bold) -> UIFont {
        UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }
}
