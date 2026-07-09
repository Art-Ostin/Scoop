//
//  ImageRatios.swift
//  Scoop Test
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI

//The Ratio of images in the app
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

extension View {
    /// `.aspectRatio(.profileCard, contentMode: .fit)`
    func aspectRatio(_ aspect: AspectRatio, contentMode: ContentMode) -> some View {
        aspectRatio(aspect.ratio, contentMode: contentMode)
    }
}



