//
//  GeneralParameters.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2026.
//

import SwiftUI

// MARK: - Corner Radius
enum Corner {
    // Standardised scale
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24

    // Key elements used throughout the app
    static let image = xl
    static let thumb = sm
    static let alert: CGFloat = 36

    // Radius for a view inset inside a rounded parent, so both curves share a center.
    static func concentric(in parent: CGFloat, inset: CGFloat) -> CGFloat {
        max(parent - inset, 4)
    }
}

// MARK: - Spacing

enum Spacing {
    
}

// MARK: - Aspect Ratio

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

