//
//  GeneralParameters.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2026.
//

import SwiftUI


// MARK: Corner Radius
enum CornerRadius {
    // Standardised scale
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24

    //Specific uses
    static let smallImage = sm
    static let image = lg
    static let alert: CGFloat = 36
    static let customMenu: CGFloat = 26
    static let customMenuRowHighlight: CGFloat = 14

    //To construct concentric corners
    static func concentric(in parent: CGFloat, inset: CGFloat) -> CGFloat {
        max(parent - inset, 4)
    }
}

// MARK: Spacing
enum Spacing {
    static let gutter: CGFloat = 16 //Standard horizontal inset between full-width content and the screen edge
}

// MARK: Shadows


// MARK:  Aspect Ratio
enum AspectRatio {
    case square, card, `default`, inviteCard

    var ratio: CGFloat {
        switch self {
        case .square:     1 / 1
        case .card:       1 / 1.05
        case .default:    1 / 1.12
        case .inviteCard: 1 / 1.5
        }
    }
}









// MARK: - View Conveniences
extension View {
    
    
    
    
    /// `.aspectRatio(.card, contentMode: .fit)`
    func aspectRatio(_ aspect: AspectRatio, contentMode: ContentMode) -> some View {
        aspectRatio(aspect.ratio, contentMode: contentMode)
    }
}

