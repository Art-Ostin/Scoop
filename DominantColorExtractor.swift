//
//  DominantColorExtractor.swift
//  Scoop Test
//
//  Created by Art Ostin on 18/07/2026.

import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins
import DominantColors

/// How loudly the secondary text reads against the scrim.
///
/// Each preset fixes the *look* — a saturation and brightness — plus a contrast
/// floor. The solver keeps that look wherever the scrim can afford it and only
/// brightens, then desaturates, when the floor demands more.
///
/// The targets come from measuring App Store Today cards: their info text sits
/// around 25–35% saturation at 80–100% brightness (#D1B391 on Duck Detective,
/// #BAFDFE on Tasty Travels) — a solid colored tint, never white at reduced
/// opacity.
enum TextProminence {

    /// 4.5:1 and the most color. What the App Store measures at.
    case subtle

    /// 6:1. Brighter and paler, still visibly tinted.
    case standard

    /// 8:1. Nearly as loud as the title, only a faint tint left.
    case prominent

    /// Pick the look and floor yourself. Useful for the large-text discount:
    /// at 18pt regular or 14pt bold the requirement drops to 3:1, which leaves
    /// far more room for saturation.
    case custom(saturation: CGFloat, brightness: CGFloat, contrast: CGFloat)

    var saturation: CGFloat {
        switch self {
        // Measured App Store cards sit at ~0.32; this is pulled a quarter of
        // the way toward white on purpose — the preferred look for this app.
        case .subtle: 0.24
        case .standard: 0.2
        case .prominent: 0.14
        case .custom(let saturation, _, _): saturation
        }
    }

    var brightness: CGFloat {
        switch self {
        case .subtle: 0.92
        case .standard: 0.94
        case .prominent: 0.97
        case .custom(_, let brightness, _): brightness
        }
    }

    var contrast: CGFloat {
        switch self {
        case .subtle: 4.5
        case .standard: 6
        case .prominent: 8
        case .custom(_, _, let contrast): contrast
        }
    }

    /// Ceiling on how much color the tint ships with, applied after the solve
    /// rather than folded into `saturation`: lowering that would brighten the
    /// tint, which raises the scrim's ceiling and leaves the artwork less
    /// covered. Capping here quiets the text over the same scrim.
    ///
    /// The presets ship quiet. `.custom` is taken at its word — a caller that
    /// names a saturation has already made the decision, so it is not quieted
    /// again.
    var chromaCap: CGFloat {
        switch self {
        case .subtle, .standard, .prominent: 0.12
        case .custom(let saturation, _, _): saturation
        }
    }
}

/// The colors a card's overlay needs, derived from the artwork.
///
/// `surface` and `scrimOpacity` describe the gradient painted over the bottom
/// of the artwork. `secondaryText` is a bright saturated tint in the hue of
/// the strip the text actually sits on, solved so that it clears the contrast
/// target against that scrim.
struct OverlayPalette: Equatable {

    /// Tint for the bottom scrim. A very dark version of the dominant color.
    var surface: Color

    /// How opaque that scrim has to be for the text to stay legible.
    var scrimOpacity: Double

    /// Bright tint of the bottom strip's hue, for secondary text. Ships already
    /// chroma-capped — use it as-is; capping again only costs color.
    var secondaryText: Color

    /// Contrast ratio `secondaryText` actually achieves. Below the requested
    /// target only when the artwork was too bright to fully scrim.
    var achievedContrast: Double

    static let placeholder = OverlayPalette(
        surface: .black,
        scrimOpacity: 0.55,
        secondaryText: Color(white: 0.82),
        achievedContrast: 0
    )
}

@MainActor
final class PopupColorExtractor {

    static let shared = PopupColorExtractor()

    private let cache = NSCache<NSString, UIColor>()
    private let paletteCache = NSCache<NSString, PaletteBox>()

    private init() {
        cache.countLimit = 100
        paletteCache.countLimit = 100
    }

    /// Returns one final color to share between a popup and its pill.
    ///
    /// - Parameters:
    ///   - imageName: Asset-catalog image name and cache identity.
    ///   - themeColor: Optional manually supplied color. This takes priority.
    ///   - fallbackColor: Used when the image or extraction fails.
    func extractColor(
        _ imageName: String,
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

        let cacheKey = imageName as NSString

        if let cachedColor = cache.object(forKey: cacheKey) {
            return Color(uiColor: cachedColor)
        }

        guard let cgImage = UIImage(named: imageName)?.cgImage else {
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
            cache.setObject(finalColor, forKey: cacheKey)
        }

        return Color(uiColor: finalColor)
    }

    /// Returns the scrim *and* the text tint for a card.
    ///
    /// The text tint is chosen first, because that is the visible design
    /// decision: the hue of the strip the text sits on, at the preset's
    /// saturation and brightness. The scrim is then darkened — and made more
    /// opaque — until that tint clears `contrast`. That ordering is what keeps
    /// the text colored instead of collapsing to white.
    ///
    /// - Parameters:
    ///   - image: The artwork to sample.
    ///   - id: Cache identity for `image`. A UIImage carries no stable key of
    ///     its own, so the caller supplies one (a profile/event id). Two
    ///     different pictures MUST NOT share an id, or one wears the other's
    ///     palette.
    ///   - prominence: How loud the secondary text should be. Trading color for
    ///     contrast, not scrim darkness — see `TextProminence`.
    ///   - textRegionHeight: Fraction of the card, measured up from the bottom,
    ///     that the overlay text covers. Must match where the scrim goes flat.
    ///   - cardAspectRatio: Width over height of the card the image fills.
    ///     Sampling reads only the part of the image the crop leaves visible.
    ///   - preferredScrimOpacity: Opacity to use when the artwork is already
    ///     dark enough behind the text.
    ///   - maximumScrimOpacity: How opaque the scrim may become while chasing
    ///     the contrast target.
    ///   - maximumDominantLuminance: Prefer a source color the artwork already
    ///     has at or below this luminance, over the most frequent one darkened.
    ///     Choosing beats blackening — the tone belongs to the photo.
    ///   - minimumSurfaceChroma: Saturation the scrim tint is brought up to when
    ///     the artwork's own is quieter. Holds luminance, so the scrim reads more
    ///     colored without getting any lighter. Gamut-bounded — a very dark hue
    ///     reaches what it can.
    ///   - maximumSurfaceLuminance: Lightest the scrim tint is allowed to be.
    ///     Contrast already caps it; pass a lower value when the design wants a
    ///     deeper tint than legibility alone asks for. Note the solver spends the
    ///     slack: a darker tint clears the ceiling sooner, so it hands opacity
    ///     back. Raise `preferredScrimOpacity` too if you want a heavier scrim.
    ///   - fallbackColor: Used when the image or extraction fails.
    func extractPalette(
        _ image: UIImage,
        id: String,
        prominence: TextProminence = .subtle,
        textRegionHeight: CGFloat = 0.18,
        cardAspectRatio: CGFloat = 1 / 1.2,
        preferredScrimOpacity: CGFloat = 0.5,
        maximumScrimOpacity: CGFloat = 0.95,
        maximumDominantLuminance: CGFloat = 1,
        minimumSurfaceChroma: CGFloat = 0,
        maximumSurfaceLuminance: CGFloat = 1,
        fallbackColor: UIColor = .black
    ) async -> OverlayPalette {
        let saturation = prominence.saturation
        let brightness = prominence.brightness
        let contrast = prominence.contrast
        let chromaCap = prominence.chromaCap

        let cacheKey = [
            id,
            "\(saturation)", "\(brightness)", "\(contrast)", "\(chromaCap)",
            "\(textRegionHeight)", "\(cardAspectRatio)",
            "\(preferredScrimOpacity)", "\(maximumScrimOpacity)",
            "\(maximumDominantLuminance)", "\(maximumSurfaceLuminance)",
            "\(minimumSurfaceChroma)"
        ].joined(separator: "|") as NSString

        if let cached = paletteCache.object(forKey: cacheKey) {
            return cached.palette
        }

        // CIImage-backed images have no cgImage; nothing to sample.
        guard let cgImage = image.cgImage else {
            return .placeholder
        }

        let artwork = await Task.detached(
            priority: .userInitiated
        ) { () -> (dominant: CGColor?, backdrop: UIColor?, strip: UIColor?) in
            (
                Self.extractDominantSource(
                    from: cgImage,
                    preferringLuminanceAtMost: maximumDominantLuminance
                ),
                Self.brightestBottomSample(
                    of: cgImage,
                    fraction: textRegionHeight,
                    cardAspectRatio: cardAspectRatio
                ),
                Self.averageBottomColor(
                    of: cgImage,
                    fraction: textRegionHeight,
                    cardAspectRatio: cardAspectRatio
                )
            )
        }.value

        let palette = Self.solvePalette(
            dominant: UIColor(cgColor: artwork.dominant ?? fallbackColor.cgColor),
            // No sample means no guarantee, so assume the worst case.
            backdrop: artwork.backdrop ?? .white,
            hueSource: artwork.strip,
            saturation: saturation,
            brightness: brightness,
            contrast: contrast,
            chromaCap: chromaCap,
            preferredOpacity: preferredScrimOpacity,
            maximumOpacity: maximumScrimOpacity,
            maximumSurfaceLuminance: maximumSurfaceLuminance,
            minimumSurfaceChroma: minimumSurfaceChroma
        )

        if artwork.dominant != nil {
            paletteCache.setObject(PaletteBox(palette), forKey: cacheKey)
        }

        return palette
    }

    func clearCache() {
        cache.removeAllObjects()
        paletteCache.removeAllObjects()
    }
}

private final class PaletteBox {

    let palette: OverlayPalette

    init(_ palette: OverlayPalette) {
        self.palette = palette
    }
}

// MARK: - Dominant color

extension PopupColorExtractor {

    /// The artwork's source color, optionally biased toward a dark one.
    ///
    /// `limit` picks the most frequent color the photo already contains that is
    /// dark enough to scrim with, rather than taking the most frequent overall
    /// and blackening it. Same darkness either way, but a tone the artwork owns
    /// instead of a fabricated one. Falls back to the most frequent color when
    /// nothing qualifies, so the solve still has something to darken.
    nonisolated static func extractDominantSource(
        from image: CGImage,
        preferringLuminanceAtMost limit: CGFloat = 1
    ) -> CGColor? {
        // Exclude black and white as source colors, but allow gray.
        if let palette = try? DominantColors.dominantColors(
            image: image,
            quality: .high,
            maxCount: 8,
            options: [.excludeBlack, .excludeWhite],
            sorting: .frequency
        ),
        let dominantColor = darkest(in: palette, atMost: limit) {
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

        return darkest(in: palette, atMost: limit)
    }

    /// The most frequent color at or below `limit`, else the most frequent overall.
    /// Frequency order is kept inside the qualifying set, so this is "the photo's
    /// main dark tone", not "the darkest pixel it happens to contain".
    nonisolated static func darkest(
        in palette: [CGColor],
        atMost limit: CGFloat
    ) -> CGColor? {
        palette.first { luminance(of: UIColor(cgColor: $0)) <= limit } ?? palette.first
    }
}

// MARK: - Palette solving

private extension PopupColorExtractor {

    /// Builds the scrim and the text tint so that the text is guaranteed to
    /// clear `contrast` against what it actually lands on: the artwork with the
    /// scrim composited over it.
    nonisolated static func solvePalette(
        dominant: UIColor,
        backdrop: UIColor,
        hueSource: UIColor?,
        saturation: CGFloat,
        brightness: CGFloat,
        contrast: CGFloat,
        chromaCap: CGFloat,
        preferredOpacity: CGFloat,
        maximumOpacity: CGFloat,
        maximumSurfaceLuminance: CGFloat,
        minimumSurfaceChroma: CGFloat
    ) -> OverlayPalette {
        // 1. Pick the tint the text wants: the hue of the strip it sits on —
        //    when the photo as a whole corroborates it — at the preset's
        //    saturation and brightness. Falls back to the dominant color's
        //    hue, and to a neutral tint when that is gray too.
        let hue = corroboratedHue(strip: hueSource, dominant: dominant)
        let tintSaturation = hue == nil ? 0 : saturation

        var text = tint(
            hue: hue ?? 0,
            saturation: tintSaturation,
            brightness: brightness
        )

        // 2. Work out how dark the scrim has to be for that tint to pass.
        //    The white title is the easier of the two, so the tinted text sets
        //    the ceiling.
        let ceiling = min(
            backgroundCeiling(for: contrast, under: luminance(of: text)),
            backgroundCeiling(for: contrast, under: 1)
        )

        let scrim = solveScrim(
            tint: dominant,
            backdrop: backdrop,
            ceiling: ceiling,
            preferredOpacity: preferredOpacity,
            maximumOpacity: maximumOpacity,
            maximumSurfaceLuminance: maximumSurfaceLuminance
        )

        // 3. If the scrim ran out of room, spend the shortfall on the text —
        //    brightening first, giving up saturation only as a last resort.
        let composited = luminance(
            of: composite(scrim.surface, opacity: scrim.opacity, over: backdrop)
        )

        let floor = foregroundFloor(for: contrast, over: composited)

        if floor > luminance(of: text) {
            text = raiseTint(
                hue: hue ?? 0,
                saturation: tintSaturation,
                baseBrightness: brightness,
                toLuminance: floor
            )
        }

        // 4. Quiet the tint down to its cap and bring the scrim up to its floor.
        //    Neither moves luminance, so the contrast solved above still holds
        //    and the scrim stays put — the only thing that changes is how loud
        //    the colors read.
        return OverlayPalette(
            surface: Color(uiColor: chromaRaised(scrim.surface, to: minimumSurfaceChroma)),
            scrimOpacity: Double(scrim.opacity),
            secondaryText: Color(uiColor: chromaCapped(text, to: chromaCap)),
            achievedContrast: Double(
                (luminance(of: text) + 0.05) / (composited + 0.05)
            )
        )
    }

    /// Darkens the tint first, then raises opacity, then darkens toward black
    /// as a last resort. Darkening the tint before touching opacity is what
    /// keeps the scrim reading as a colored shadow rather than a black bar.
    nonisolated static func solveScrim(
        tint: UIColor,
        backdrop: UIColor,
        ceiling: CGFloat,
        preferredOpacity: CGFloat,
        maximumOpacity: CGFloat,
        maximumSurfaceLuminance: CGFloat
    ) -> (surface: UIColor, opacity: CGFloat) {
        // A little under the ceiling, so opacity has something to work with,
        // and never lighter than the caller will accept.
        let surface = adjust(
            tint,
            toLuminance: min(
                luminance(of: tint),
                ceiling * 0.6,
                maximumSurfaceLuminance
            )
        )

        func composited(_ opacity: CGFloat, _ color: UIColor) -> CGFloat {
            luminance(of: composite(color, opacity: opacity, over: backdrop))
        }

        if composited(preferredOpacity, surface) <= ceiling {
            return (surface, preferredOpacity)
        }

        if composited(maximumOpacity, surface) <= ceiling {
            var lower = preferredOpacity
            var upper = maximumOpacity

            for _ in 0..<12 {
                let opacity = (lower + upper) / 2

                if composited(opacity, surface) <= ceiling {
                    upper = opacity
                } else {
                    lower = opacity
                }
            }

            return (surface, upper)
        }

        // Bright artwork behind the text: keep the maximum opacity and pull the
        // tint the rest of the way toward black.
        var lower: CGFloat = 0
        var upper: CGFloat = 1
        var darkened = UIColor.black

        for _ in 0..<12 {
            let amount = (lower + upper) / 2
            let candidate = mix(surface, with: .black, by: amount)

            if composited(maximumOpacity, candidate) <= ceiling {
                darkened = candidate
                upper = amount
            } else {
                lower = amount
            }
        }

        return (darkened, maximumOpacity)
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

        guard luminance(of: opaqueSource) > maximumLuminance else {
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

            if luminance(of: candidate) <= maximumLuminance {
                result = candidate
                lowerScale = scale
            } else {
                upperScale = scale
            }
        }

        return result
    }
}

// MARK: - Artwork sampling

private extension PopupColorExtractor {

    static let ciContext = CIContext(
        options: [.cacheIntermediates: false]
    )

    static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)

    /// The part of the image a `scaledToFill` card actually shows, in CIImage
    /// (bottom-origin) coordinates. Sampling the raw image instead would read
    /// cropped-off pixels: a portrait photo in a 1:1.2 card loses its top and
    /// bottom edges, so "the bottom of the image" is not the bottom of the card.
    nonisolated static func visibleRect(
        of image: CGImage,
        cardAspectRatio: CGFloat
    ) -> CGRect {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let imageAspect = width / height

        if imageAspect > cardAspectRatio {
            let visibleWidth = height * cardAspectRatio
            return CGRect(
                x: (width - visibleWidth) / 2,
                y: 0,
                width: visibleWidth,
                height: height
            )
        }

        let visibleHeight = width / cardAspectRatio
        return CGRect(
            x: 0,
            y: (height - visibleHeight) / 2,
            width: width,
            height: visibleHeight
        )
    }

    /// Average color of the brightest tile of the visible bottom strip.
    ///
    /// The strip is what sits behind the overlay text once Glur has blurred it,
    /// so its average is a good stand-in for the real backdrop. The tiles are
    /// sized near a text line so a small bright feature — a collar, a lamp —
    /// dominates its tile instead of being diluted away by a wide slice, which
    /// is what keeps the contrast guarantee honest.
    nonisolated static func brightestBottomSample(
        of image: CGImage,
        fraction: CGFloat,
        cardAspectRatio: CGFloat,
        columns: Int = 8,
        rows: Int = 2
    ) -> UIColor? {
        guard image.width > 0, image.height > 0 else { return nil }

        let visible = visibleRect(of: image, cardAspectRatio: cardAspectRatio)
        let stripHeight = max(visible.height * min(max(fraction, 0.01), 1), 1)
        let tileWidth = visible.width / CGFloat(columns)
        let tileHeight = stripHeight / CGFloat(rows)

        var brightest: UIColor?
        var brightestLuminance: CGFloat = -1

        for row in 0..<rows {
            for column in 0..<columns {
                // CIImage uses a bottom-left origin, so visible.minY is the
                // bottom edge of what the card shows.
                let rect = CGRect(
                    x: visible.minX + tileWidth * CGFloat(column),
                    y: visible.minY + tileHeight * CGFloat(row),
                    width: tileWidth,
                    height: tileHeight
                )

                guard let sample = averageColor(of: image, in: rect) else {
                    continue
                }

                let sampleLuminance = luminance(of: sample)

                if sampleLuminance > brightestLuminance {
                    brightestLuminance = sampleLuminance
                    brightest = sample
                }
            }
        }

        return brightest
    }

    /// Plain average of the whole visible bottom strip — the hue the text
    /// should harmonize with. `brightestBottomSample` guards the contrast
    /// worst case; this one matches what the blur actually shows.
    nonisolated static func averageBottomColor(
        of image: CGImage,
        fraction: CGFloat,
        cardAspectRatio: CGFloat
    ) -> UIColor? {
        guard image.width > 0, image.height > 0 else { return nil }

        let visible = visibleRect(of: image, cardAspectRatio: cardAspectRatio)
        let stripHeight = max(visible.height * min(max(fraction, 0.01), 1), 1)

        return averageColor(
            of: image,
            in: CGRect(
                x: visible.minX,
                y: visible.minY,
                width: visible.width,
                height: stripHeight
            )
        )
    }

    nonisolated static func averageColor(
        of image: CGImage,
        in rect: CGRect
    ) -> UIColor? {
        let filter = CIFilter.areaAverage()
        filter.inputImage = CIImage(cgImage: image)
        filter.extent = rect

        guard let output = filter.outputImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)

        ciContext.render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: sRGB
        )

        return UIColor(
            red: CGFloat(pixel[0]) / 255,
            green: CGFloat(pixel[1]) / 255,
            blue: CGFloat(pixel[2]) / 255,
            alpha: 1
        )
    }
}

// MARK: - Color math

private extension PopupColorExtractor {

    /// WCAG 2.x relative luminance, computed locally. DominantColors'
    /// `relativeLuminance` rounds to 3 decimals, which is enough slack for a
    /// solve that converges onto the threshold to land just below the true
    /// contrast floor.
    nonisolated static func luminance(of color: UIColor) -> CGFloat {
        guard let rgb = components(of: color) else { return 0 }

        return 0.2126 * linearized(rgb.red)
            + 0.7152 * linearized(rgb.green)
            + 0.0722 * linearized(rgb.blue)
    }

    /// The sRGB transfer function and its inverse. Shared so the linear and the
    /// gamma-encoded halves of the color math can't drift apart.
    nonisolated static func linearized(_ channel: CGFloat) -> CGFloat {
        channel <= 0.04045
            ? channel / 12.92
            : pow((channel + 0.055) / 1.055, 2.4)
    }

    nonisolated static func encoded(_ channel: CGFloat) -> CGFloat {
        channel <= 0.0031308
            ? channel * 12.92
            : 1.055 * pow(channel, 1 / 2.4) - 0.055
    }

    /// Pulls `color`'s chroma down until its HSB saturation reads about `cap`,
    /// holding relative luminance exactly — the luminance weights sum to 1, so
    /// lerping every linear channel toward the color's own luminance leaves that
    /// luminance where it was, and a contrast solved against it still holds.
    ///
    /// A cap rather than a scale: colors already at or below `cap` come back
    /// untouched, so an extraction that was quiet to begin with is never pushed
    /// further toward gray. The threshold is read in HSB but the correction is
    /// applied in linear light, so the result lands near `cap` rather than on it
    /// — exact on the luminance, approximate on the number.
    nonisolated static func chromaCapped(
        _ color: UIColor,
        to cap: CGFloat
    ) -> UIColor {
        guard
            let tone = hsb(of: color),
            tone.saturation > cap,
            let rgb = components(of: color)
        else {
            return color
        }

        let amount = 1 - cap / tone.saturation
        let red = linearized(rgb.red)
        let green = linearized(rgb.green)
        let blue = linearized(rgb.blue)
        let target = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        return UIColor(
            red: encoded(red + (target - red) * amount),
            green: encoded(green + (target - green) * amount),
            blue: encoded(blue + (target - blue) * amount),
            alpha: color.cgColor.alpha
        )
    }

    /// Pushes `color`'s chroma up until its HSB saturation reads about `floor` —
    /// the mirror of `chromaCapped`, and the only way to make a scrim's hue read
    /// louder without lightening it. Mixing toward black scales all three
    /// channels together, so it leaves saturation exactly where it was; this
    /// spreads them apart instead, and holds luminance for the same reason
    /// `chromaCapped` does.
    ///
    /// Bounded by the gamut rather than clamped into it: a dark hue with no room
    /// left stops where it stops, instead of clipping a channel and dragging its
    /// luminance off the value the contrast solve depends on.
    nonisolated static func chromaRaised(
        _ color: UIColor,
        to floor: CGFloat
    ) -> UIColor {
        guard
            let tone = hsb(of: color),
            tone.saturation < floor,
            let rgb = components(of: color)
        else {
            return color
        }

        let red = linearized(rgb.red)
        let green = linearized(rgb.green)
        let blue = linearized(rgb.blue)
        let target = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        func spread(by amount: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
            (red + (red - target) * amount,
             green + (green - target) * amount,
             blue + (blue - target) * amount)
        }

        func fits(_ channels: (CGFloat, CGFloat, CGFloat)) -> Bool {
            [channels.0, channels.1, channels.2].allSatisfy { $0 >= 0 && $0 <= 1 }
        }

        func made(_ channels: (CGFloat, CGFloat, CGFloat)) -> UIColor {
            UIColor(
                red: encoded(channels.0),
                green: encoded(channels.1),
                blue: encoded(channels.2),
                alpha: color.cgColor.alpha
            )
        }

        // Saturation and gamut pressure both rise with the amount, so the usable
        // amounts are one range from zero — bisect for where it ends.
        var lower: CGFloat = 0
        var upper: CGFloat = 8
        var result = color

        for _ in 0..<16 {
            let amount = (lower + upper) / 2
            let channels = spread(by: amount)
            let candidate = made(channels)

            if fits(channels), (hsb(of: candidate)?.saturation ?? floor) <= floor {
                result = candidate
                lower = amount
            } else {
                upper = amount
            }
        }

        return result
    }

    /// Lowest luminance a foreground can have and still reach `contrast`.
    nonisolated static func foregroundFloor(
        for contrast: CGFloat,
        over background: CGFloat
    ) -> CGFloat {
        contrast * (background + 0.05) - 0.05
    }

    /// Highest luminance a background can have and still give a foreground of
    /// luminance `foreground` a ratio of `contrast`.
    nonisolated static func backgroundCeiling(
        for contrast: CGFloat,
        under foreground: CGFloat
    ) -> CGFloat {
        (foreground + 0.05) / contrast - 0.05
    }

    /// The tint hue: the strip's, when the photo as a whole backs it up.
    ///
    /// A strip hue can be driven by a single chromatic object against neutral
    /// surroundings — one orange speaker on gray grass reads as a pink strip
    /// average. The dominant color is the photo's identity, so the strip hue
    /// only wins when the two roughly agree; on conflict the dominant speaks
    /// for the card. When only one of them has a hue at all, it stands.
    nonisolated static func corroboratedHue(
        strip: UIColor?,
        dominant: UIColor
    ) -> CGFloat? {
        let stripHue = usableHue(of: strip)
        let dominantHue = usableHue(of: dominant)

        guard let stripHue else { return dominantHue }
        guard let dominantHue else { return stripHue }

        // Hue is circular; 0.125 is 45 degrees.
        let difference = abs(stripHue - dominantHue)
        let distance = min(difference, 1 - difference)

        return distance <= 0.125 ? stripHue : dominantHue
    }

    /// The hue of `color`, if it has enough color to read as a hue at all.
    ///
    /// Gated on absolute chroma, not HSB saturation: saturation is chroma
    /// divided by brightness, so on a near-black strip a 2/255 quantization
    /// wobble reads as 20% "saturation" and would tint the text a random hue.
    /// Near-grays and near-blacks both fall through to the fallback instead.
    nonisolated static func usableHue(of color: UIColor?) -> CGFloat? {
        guard let color, let rgb = components(of: color) else { return nil }

        let brightest = max(rgb.red, rgb.green, rgb.blue)
        let chroma = brightest - min(rgb.red, rgb.green, rgb.blue)

        guard
            chroma >= 0.04,
            brightest >= 0.15,
            let components = hsb(of: color)
        else {
            return nil
        }

        return components.hue
    }

    nonisolated static func tint(
        hue: CGFloat,
        saturation: CGFloat,
        brightness: CGFloat
    ) -> UIColor {
        UIColor(
            hue: hue,
            saturation: saturation,
            brightness: brightness,
            alpha: 1
        )
    }

    /// Lifts the tint to `target` luminance while giving up as little color as
    /// possible: brightness rises to full first, saturation drains only after.
    /// Luminance is monotonic in both, so each stage is a plain bisection.
    nonisolated static func raiseTint(
        hue: CGFloat,
        saturation: CGFloat,
        baseBrightness: CGFloat,
        toLuminance target: CGFloat
    ) -> UIColor {
        let clampedTarget = min(max(target, 0), 1)

        let fullBrightness = tint(hue: hue, saturation: saturation, brightness: 1)

        if luminance(of: fullBrightness) >= clampedTarget {
            var lower = baseBrightness
            var upper: CGFloat = 1
            var result = fullBrightness

            for _ in 0..<16 {
                let brightness = (lower + upper) / 2
                let candidate = tint(
                    hue: hue,
                    saturation: saturation,
                    brightness: brightness
                )

                if luminance(of: candidate) < clampedTarget {
                    lower = brightness
                } else {
                    result = candidate
                    upper = brightness
                }
            }

            return result
        }

        // Even full brightness fell short: keep the highest saturation that
        // still clears the target. Saturation 0 is white, so this always lands.
        var lower: CGFloat = 0
        var upper = saturation
        var result = UIColor.white

        for _ in 0..<16 {
            let candidateSaturation = (lower + upper) / 2
            let candidate = tint(
                hue: hue,
                saturation: candidateSaturation,
                brightness: 1
            )

            if luminance(of: candidate) < clampedTarget {
                upper = candidateSaturation
            } else {
                result = candidate
                lower = candidateSaturation
            }
        }

        return result
    }

    /// Moves `color` toward white or black until it hits `target` relative
    /// luminance. Blending toward white is what turns the dominant color into a
    /// tint: it keeps the hue and drops the saturation as it lightens.
    nonisolated static func adjust(
        _ color: UIColor,
        toLuminance target: CGFloat
    ) -> UIColor {
        let clampedTarget = min(max(target, 0), 1)
        let current = luminance(of: color)

        guard abs(current - clampedTarget) > 0.001 else { return color }

        let lightening = current < clampedTarget
        let anchor: UIColor = lightening ? .white : .black

        var lower: CGFloat = 0
        var upper: CGFloat = 1
        var result = color

        // Luminance moves monotonically with the blend amount, so bisection
        // lands on the exact tone in a fixed number of steps.
        for _ in 0..<16 {
            let amount = (lower + upper) / 2
            result = mix(color, with: anchor, by: amount)

            let tooDark = luminance(of: result) < clampedTarget

            if tooDark == lightening {
                lower = amount
            } else {
                upper = amount
            }
        }

        return result
    }

    /// Source-over blend, done in the same gamma-encoded space SwiftUI
    /// composites in, so the result matches what actually renders.
    nonisolated static func composite(
        _ tint: UIColor,
        opacity: CGFloat,
        over base: UIColor
    ) -> UIColor {
        mix(base, with: tint, by: min(max(opacity, 0), 1))
    }

    nonisolated static func mix(
        _ color: UIColor,
        with other: UIColor,
        by amount: CGFloat
    ) -> UIColor {
        guard
            let from = components(of: color),
            let to = components(of: other)
        else {
            return color
        }

        return UIColor(
            red: from.red + (to.red - from.red) * amount,
            green: from.green + (to.green - from.green) * amount,
            blue: from.blue + (to.blue - from.blue) * amount,
            alpha: 1
        )
    }

    nonisolated static func components(
        of color: UIColor
    ) -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getRed(
            &red,
            green: &green,
            blue: &blue,
            alpha: &alpha
        ) else {
            return nil
        }

        return (red, green, blue)
    }

    nonisolated static func hsb(
        of color: UIColor
    ) -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat)? {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getHue(
            &hue,
            saturation: &saturation,
            brightness: &brightness,
            alpha: &alpha
        ) else {
            return nil
        }

        return (hue, saturation, brightness)
    }
}

