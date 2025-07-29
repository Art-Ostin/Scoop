//
//  ColorMenu.swift
//  ScoopTest
//
//  Created by Art Ostin on 20/06/2025.
//


// Default UI for The App


import SwiftUI


extension Color {
        
    static let background = Color(red: 0.98, green: 0.98, blue: 0.99)

    static let grayBackground = Color (red: 0.93, green: 0.93, blue: 0.93)
    
    static let grayText = Color (red: 0.6, green: 0.6, blue: 0.6)
    
    static let grayPlaceholder = Color (red: 0.85, green: 0.85, blue: 0.85)
    
    static let secondary = Color (red: 0, green: 0.6, blue: 0.52)
    
    static let defualtGreen =  Color (red: 0.16, green: 0.65, blue: 0.27)
}

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
