//
//  ImageElements.swift
//  Scoop
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI
import Glur
import CoreImage
import CoreImage.CIFilterBuiltins


enum AppImageType {case meet, invite}

struct AppImage: View {

    let image: UIImage
    let type: AppImageType
    
    var aspectRatio: CGFloat { type == .meet ? 1/1.2 : 1/1.55}
        
    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: 20))
            .containerRelativeFrame(.horizontal) { length, _ in
                return max(length - 16 * 2, 0)
            }//No padding but this method so overlay content works
    }
}

//One carousel page: fill-crop, softened bottom, sharp edges. Shared between the live pager
//and the invite flight's static covers so the swap between them is pixel-identical.
struct InvitePagePhoto: View {

    //Glur drops its whole layerEffect at exactly 0, and that structural swap flashes the page
    //mid-morph. A hair above zero keeps the shader mounted through the screen change: its
    //64-tap Gaussian collapses onto the centre sample, so it reads as untouched artwork.
    private static let blurOff: CGFloat = 0.01
    private static let blurOn: CGFloat = 14
    private static let blurStart: CGFloat = 0.85 //Fraction of the height where the ramp begins — shared with the baked copy below
    private static let blurInterpolation: CGFloat = 0.3 //Glur ramps σ = radius·(y/h − start)/interpolation, capped — so the EDGE only reaches radius·(1−start)/interpolation (7pt here), linearly

    let image: UIImage
    let blursBottom: Bool

    var body: some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .glur(radius: blursBottom ? Self.blurOn : Self.blurOff, offset: Self.blurStart, interpolation: Self.blurInterpolation, direction: .down, noise: 0)
            .mask {
                VStack(spacing: 0) {
                    Rectangle() // Left, right and top stay razor sharp.
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 2)
                }
            }
            .clipped() //scaledToFill overflows the cell
    }
}

//MARK: Baked bottom blur — the invite flight's flyable copy of this page's glur
extension InvitePagePhoto {

    private static let bakeContext = CIContext()

    ///The page's progressive bottom blur baked into plain pixels, matching the `.glur` call in
    ///`body` (ramp from `blurStart` of the height to `blurOn` at the bottom edge; glur's
    ///`interpolation` is approximated by the gradient's smooth hermite ramp). The invite
    ///flight flies images, never live shaders — a glur layerEffect at animated size drops the
    ///device to ~15fps — so the blur can only ride the open flight pre-rendered.
    static func bakedBottomBlur(for image: UIImage, aspect: CGFloat, displayWidth: CGFloat, scale: CGFloat) -> UIImage? {
        let target = CGSize(width: (displayWidth * scale).rounded(),
                            height: (displayWidth / aspect * scale).rounded())
        guard target.width > 0, target.height > 0, image.size.width > 0, image.size.height > 0 else { return nil }

        //One draw normalises orientation, centre-crops (scaledToFill) and downsamples to the
        //page's on-screen pixel size, so the blur radius below is in glur's own units.
        //Standard range: extended/P3 content through the default CIContext gamut-shifts the
        //sharp region against rawCover's original (this project's P3 scars run deep).
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.preferredRange = .standard
        let flat = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            let fill = max(target.width / image.size.width, target.height / image.size.height)
            let drawSize = CGSize(width: image.size.width * fill, height: image.size.height * fill)
            image.draw(in: CGRect(x: (target.width - drawSize.width) / 2,
                                  y: (target.height - drawSize.height) / 2,
                                  width: drawSize.width, height: drawSize.height))
        }
        guard let source = flat.cgImage else { return nil }

        //Core Image's origin is bottom-left: the ramp runs from clear at (1 − blurStart)·h
        //down to the edge. LINEAR gradient and the capped edge σ — glur's shader ramps
        //σ = radius·(y/h − start)/interpolation linearly, reaching only radius·(1−start)/
        //interpolation (7pt) at the bottom edge; a smoothstep to the full 14 baked a band
        //2× too blurry that visibly sharpened under the landing crossfade (shader-read).
        let gradient = CIFilter.linearGradient()
        gradient.point0 = CGPoint(x: 0, y: target.height * (1 - Self.blurStart))
        gradient.point1 = .zero
        gradient.color0 = CIColor.black
        gradient.color1 = CIColor.white

        let blur = CIFilter.maskedVariableBlur()
        blur.inputImage = CIImage(cgImage: source).clampedToExtent() //Clamped so the edge doesn't darken
        blur.mask = gradient.outputImage
        blur.radius = Float(Self.blurOn * scale * (1 - Self.blurStart) / Self.blurInterpolation)

        let extent = CGRect(origin: .zero, size: target)
        guard let output = blur.outputImage?.cropped(to: extent),
              let baked = Self.bakeContext.createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: baked, scale: scale, orientation: .up)
    }
}

struct InviteCarousel: View {

    //Injected Properties
    let images: [UIImage]
    let isCompact: Bool
    let blursBottom: Bool

    //The invite flight frames this carousel itself; aspect sizing would fight the animated frame
    var fillsFrame: Bool = false

    //The flight snaps the pager home under a cover before resizing it
    var position: Binding<ScrollPosition>? = nil

    @Binding var scrollProgress: Double

    private var ratio: CGFloat {
        (isCompact ? AspectRatio.confirmInviteImage : .invitedImage).ratio
    }

    @ViewBuilder
    var body: some View {
        if fillsFrame {
            pager
        } else {
            pager
                .aspectRatio(ratio, contentMode: .fit) //Sizes the greedy pager to the image shape
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pager: some View {
        HorizontalScrollView(progress: $scrollProgress, position: position) {
            ForEach(images, id: \.self) { image in
                InvitePagePhoto(image: image, blursBottom: blursBottom)
                    .containerRelativeFrame(.horizontal)
            }
        }
    }
}


struct SmallImage: View {
    let image: UIImage
    let size: CGFloat
    
    var radius: CGFloat = CornerRadius.smallImage
    var isCircle: Bool = false
        
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(.rect(
                cornerRadius: isCircle ? size / 2 : radius,
                style: isCircle ? .circular : .continuous
            ))
    }
}


struct InvitePageIndicator: View {
    let count: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { index in
                let closeness = max(0, 1 - abs(progress - Double(index)))

                Capsule()
                    .fill(Color.border)
                    .overlay {
                        Capsule()
                            .fill(Color.textSecondary)
                            .opacity(closeness)
                    }
                    .frame(width: 3 + 2 * CGFloat(closeness), height: 3)
            }
        }
        .frame(width: count > 0 ? 5 + CGFloat(count - 1) * 8 : 0, height: 3)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
