//
//  DominantColorExtractor.swift
//  Scoop Test
//
//  Created by Art Ostin on 18/07/2026.
//

import SwiftUI
import UIKit
import DominantColors


//Extracts the dominant color from an image and ensures it is dark enough to allow white text contrast
//It makes it darker by taking dominant colour and darkening it, until enough white contrast
/* Use
 .task {
     dominantColor = await PopupColorExtractor.shared
         .extractColor(imageName)
 }
*/

@MainActor
final class PopupColorExtractor {

    static let shared = PopupColorExtractor()

    private let cache = NSCache<UIImage, UIColor>()

    private init() {
        cache.countLimit = 100
    }

    /// Returns one final color to share between a popup and its pill.
    ///
    /// - Parameters:
    ///   - image: Source image and cache identity.
    ///   - themeColor: Optional manually supplied color. This takes priority.
    ///   - fallbackColor: Used when extraction fails.
    func extractColor(
        _ image: UIImage,
        themeColor: UIColor? = nil,
        fallbackColor: UIColor = .black
    ) async -> Color {
        if let themeColor {
            return Color(
                uiColor: Self.makeAccessibleSurface(
                    from: themeColor.cgColor
                )
            )
        }

        if let cachedColor = cache.object(forKey: image) {
            return Color(uiColor: cachedColor)
        }

        guard let cgImage = image.cgImage else {
            return Color(
                uiColor: Self.makeAccessibleSurface(
                    from: fallbackColor.cgColor
                )
            )
        }

        let extractedColor = await Task.detached(
            priority: .userInitiated
        ) {
            Self.extractDominantSource(from: cgImage)
        }.value

        let finalColor = Self.makeAccessibleSurface(
            from: extractedColor ?? fallbackColor.cgColor
        )

        if extractedColor != nil {
            cache.setObject(finalColor, forKey: image)
        }

        return Color(uiColor: finalColor)
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}

private extension PopupColorExtractor {

    nonisolated static func extractDominantSource(
        from image: CGImage
    ) -> CGColor? {
        // Exclude black and white as source colors, but allow gray.
        if let palette = try? DominantColors.dominantColors(
            image: image,
            quality: .high,
            maxCount: 8,
            options: [.excludeBlack, .excludeWhite],
            sorting: .frequency
        ),
        let dominantColor = palette.first {
            return dominantColor
        }

        // Fallback for images containing only black or white colors.
        guard let palette = try? DominantColors.dominantColors(
            image: image,
            quality: .high,
            maxCount: 8,
            sorting: .frequency
        ) else {
            return nil
        }

        return palette.first
    }

    /// Makes the color opaque and darkens it only when white text
    /// would otherwise have less than 4.5:1 contrast.
    static func makeAccessibleSurface(
        from color: CGColor
    ) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard UIColor(cgColor: color).getRed(
            &red,
            green: &green,
            blue: &blue,
            alpha: &alpha
        ) else {
            return .black
        }

        let opaqueSource = UIColor(
            red: red,
            green: green,
            blue: blue,
            alpha: 1
        )

        // Maximum background luminance that gives white text
        // a 4.5:1 contrast ratio.
        let minimumContrast: CGFloat = 4.5
        let maximumLuminance = (1.05 / minimumContrast) - 0.05

        guard opaqueSource.cgColor.relativeLuminance > maximumLuminance else {
            return opaqueSource
        }

        // Find the least amount of darkening required.
        var lowerScale: CGFloat = 0
        var upperScale: CGFloat = 1
        var result = UIColor.black

        for _ in 0..<14 {
            let scale = (lowerScale + upperScale) / 2

            let candidate = UIColor(
                red: red * scale,
                green: green * scale,
                blue: blue * scale,
                alpha: 1
            )

            if candidate.cgColor.relativeLuminance <= maximumLuminance {
                result = candidate
                lowerScale = scale
            } else {
                upperScale = scale
            }
        }

        return result
    }
}
