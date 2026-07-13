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
    
    //Keep duplicate of body and title. Allows complete freedom when filling out
    static func body(_ size: CGFloat = 16, _ weight: bodyFontWeight = .medium) -> Font {
        .custom(weight.rawValue, size: size)
    }
    
    static func body(_ weight: bodyFontWeight) -> Font {
        .body(16, weight)
    }
    
    static func title(_ size: CGFloat = 32, _ weight: titleFontWeight = .bold) -> Font {
        .custom(weight.rawValue, size: size)
    }
    
    static func title(_ weight: titleFontWeight) -> Font {
        .title(32, weight)
    }

    // SF Symbols size off the system font's point size + weight; a custom text
    // token (ModernEra/SFProRounded) would mis-render them, so symbol sizing keeps
    // its system font here — the one sanctioned home for it, never called in features.
    static func icon(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight)
    }
}

extension UIFont {
    //Needed to measure text height in message bubble etc
    static func body(_ size: CGFloat = 16, _ weight: Font.bodyFontWeight = .medium) -> UIFont {
        UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size)
    }

    //Needed for changing navigation title
    static func title(_ size: CGFloat = 32, _ weight: Font.titleFontWeight = .bold) -> UIFont {
        UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }
}
