//
//  FontTypes.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
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
        case bold = "NewYorkLarge-Bold"
        case semibold = "NewYorkMedium-Semibold"
        case medium = "NewYorkMedium-Medium"
    }
    
    static func body(_ size: CGFloat = 16, _ weight: bodyFontWeight = .medium) -> Font {
        .custom(weight.rawValue, size: size)
    }
    
    static func body(_ weight: bodyFontWeight) -> Font {
        .custom(weight.rawValue, size: 16)
    }
    
    static func title(_ size: CGFloat = 32, _ weight: titleFontWeight = .bold) -> Font {
        .custom(weight.rawValue, size: size)
    }
    
    static func title(_ weight: titleFontWeight) -> Font {
        .custom(weight.rawValue, size: 32)
    }
    
}
