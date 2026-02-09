//
//  ColorMenu.swift
//  ScoopTest
//
//  Created by Art Ostin on 20/06/2025.
//


// Default UI for The App


import SwiftUI
import UIKit





extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self {
        min(max(self, r.lowerBound), r.upperBound)
    }
}





extension Color {
    
    static let appBackground = Color(red: 0.42, green: 0.40, blue: 0.30)
        
    static let background = Color(red: 0.98, green: 0.98, blue: 0.99)

    static let grayBackground = Color (red: 0.93, green: 0.93, blue: 0.93)
    
    static let grayText = Color (red: 0.6, green: 0.6, blue: 0.6)
    
    static let grayPlaceholder = Color (red: 0.85, green: 0.85, blue: 0.85)
    
    static let secondary = Color (red: 0, green: 0.6, blue: 0.52)
    
    static let appGreen =  Color(red: 0, green: 0.6, blue: 0.52)
    
    static let appRed = Color(red: 0.86, green: 0.21, blue: 0.27)
    
    static let dangerRed = Color(red: 0.94, green: 0.08, blue: 0.24)
    
    static let warningYellow = Color(red: 1, green: 0.75, blue: 0.03)
    
    static let appColorTint = Color(red: 0.78, green: 0, blue: 0.35)
}



extension UIColor {
    static let appBackground = UIColor(red: 0.42, green: 0.40, blue: 0.30, alpha: 1)
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
    
    enum tabTitleType: String {
        case title = "SFProRounded-Bold"
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
    
    static func tabTitle(_ size: CGFloat = 32, weight: tabTitleType = .title) -> Font {
        .custom(weight.rawValue, size: size)
    }
}

extension UIFont {
    static func body(_ size: CGFloat = 16, _ weight: Font.bodyFontWeight = .medium) -> UIFont {
        UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size)
    }
}
