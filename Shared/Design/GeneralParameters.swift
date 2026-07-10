//
//  GeneralParameters.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2026.
//

import SwiftUI


// MARK: Corner Radius
//
// The app speaks one corner language:
// • One scale, 4pt apart — pick by surface size; views never invent radii.
// • One curvature: continuous, the iOS 26 SDK default for every rounded-rect API.
//   Never pass `style:`. The only sanctioned `.circular` is a rounded rect standing
//   in for a true circle (e.g. matchedTransitionSource only accepts rects).
// • Nested rounded corners share a centre: inner = concentric(in:inset:).
// • Radii replicating private system chrome (alerts, menus) are measured once, here.
enum CornerRadius {
    // Standardised scale
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24

    // Roles shared across features (morphs/flights rely on these staying in sync app-wide)
    static let smallImage = sm //Thumbnails and small tiles
    static let image = lg      //Full-width card images (profile pager, cards, flight copies)

    // System chrome stand-ins (measured on iOS 26; the native values are private)
    static let alert: CGFloat = 36              //System .alert panel; its buttons are Capsules
    static let menuPlatter: CGFloat = 26        //Context-menu platter (Liquid Glass)
    static let menuHighlight: CGFloat = 14      //Menu row selection highlight (inset, not full-bleed)
    static let legacyMenuPlatter: CGFloat = 13  //Classic pre-26 menu platter

    // Radius for a view inset inside a rounded parent, so both curves share a center.
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

