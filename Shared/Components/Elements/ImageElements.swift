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
    ///Widens the card past the type's own inset — a lone invite has no neighbour to leave room for
    var insetOverride: CGFloat? = nil

    var inset: CGFloat { insetOverride ?? (type == .meet ? Spacing.gutter : 9) } //Geometry: invite cards run 18pt apart, most of the gap a screen − 48 card leaves
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
                return max(length - inset * 2, 0)
            }//No padding but this method so overlay content works
    }
}

struct InvitePagePhoto: View {

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

    private static let bakeContext = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any
    ])

    static func bakedBottomBlur(for image: UIImage, aspect: CGFloat, displayWidth: CGFloat, scale: CGFloat) -> UIImage? {
        let pxSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        guard pxSize.width > 0, pxSize.height > 0, displayWidth > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.preferredRange = .standard
        let flat = UIGraphicsImageRenderer(size: pxSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: pxSize)) //Normalises orientation at full resolution
        }
        guard let source = flat.cgImage else { return nil }

        let cropSize = pxSize.width / pxSize.height > aspect
            ? CGSize(width: pxSize.height * aspect, height: pxSize.height)
            : CGSize(width: pxSize.width, height: pxSize.width / aspect)
        let cropMaxY = (pxSize.height + cropSize.height) / 2 //Centred crop, top-down coords
        let bandTop = cropMaxY - cropSize.height * (1 - Self.blurStart)

        let gradient = CIFilter.linearGradient()
        gradient.point0 = CGPoint(x: 0, y: pxSize.height - bandTop)
        gradient.point1 = CGPoint(x: 0, y: pxSize.height - cropMaxY)
        gradient.color0 = CIColor.black
        gradient.color1 = CIColor.white

        let blur = CIFilter.maskedVariableBlur()
        blur.inputImage = CIImage(cgImage: source).clampedToExtent() //Clamped so the edge doesn't darken
        blur.mask = gradient.outputImage
        //The capped 7pt on-screen σ converted to this image's pixels (crop width ↔ display width)
        blur.radius = Float(Self.blurOn * (1 - Self.blurStart) / Self.blurInterpolation * cropSize.width / displayWidth)

        let extent = CGRect(origin: .zero, size: pxSize)
        guard let output = blur.outputImage?.cropped(to: extent),
              let baked = Self.bakeContext.createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: baked, scale: image.scale, orientation: .up)
    }
}

struct InviteCarousel: View {

    //Injected Properties
    let images: [UIImage]
    let ratio: CGFloat

    ///Softens the artwork's bottom, for a caller that lays type over it
    var blursBottom: Bool = false

    //The invite flight frames this carousel itself; aspect sizing would fight the animated frame
    var fillsFrame: Bool = false

    //The flight snaps the pager home under a cover before resizing it
    var position: Binding<ScrollPosition>? = nil

    @Binding var scrollProgress: Double

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
