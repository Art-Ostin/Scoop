//
//  BackgroundBlur.swift
//  Scoop
//
//  Created by Art Ostin on 10/06/2026.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

//Soft blurred-image halo revealed behind text overlaid on a photo (card names/details).
struct BackgroundBlur: View {

    static let haloCornerRadius: CGFloat = 12
    static let haloBlurRadius: CGFloat = 4


    let image: UIImage
    // Label frames to reveal blur behind — in the base image's coordinate space.
    let frames: [CGRect]

    var body: some View {
        // Color.clear adopts the proposed size exactly, so the mask's coordinate
        // space matches the base image the frames were measured against.
        Color.clear
            .overlay { Image(uiImage: image).resizable().scaledToFill() }
            .blur(radius: 40)
            .mask { mask } //The stencil: which bits of the blurred image to show.
            .allowsHitTesting(false)
    }

    private var mask: some View {
        ZStack {
            ForEach(frames.indices, id: \.self) { index in
                let frame = frames[index]
                let dy = min(8, max((frame.height - 12) / 2, 0)) //Tighten the halo but never below a certain point
                let rect = frame.insetBy(dx: 0, dy: dy)


                RoundedRectangle(cornerRadius: Self.haloCornerRadius)
                    .frame(width: max(rect.width, 0), height: max(rect.height, 0))
                    .position(x: rect.midX, y: rect.midY)
                    .blur(radius: Self.haloBlurRadius) //Feather the halo edge so the reveal fades out.
                    .offset(y: 2) //Frame tops sit at ascender height ('L', 'T'); nudge the halo down.
            }
        }
    }
}

//MARK: Baked halo — the invite flight's flyable copy of this view
extension BackgroundBlur {

    //The bake keeps only the bottom strip that contains the halo's mask support (title rects
    //+ feather) — a full-slot RGBA bake would cost ~5MB per cached profile for transparency
    static let bakedStripHeight: CGFloat = 72

    //GAMMA working space, like the band bake: the live halo is a CA gaussian over
    //gamma-encoded layer pixels — a linear-light bake reads brighter than it on contrasty
    //content and the reveal crossfade darkens (device frames, 2026-08-13)
    private static let bakeContext = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any
    ])

    ///This halo baked into flat pixels, matching `body` (photo aspect-filled into `slot`,
    ///40pt gaussian with SwiftUI's transparent-edge falloff, masked by the feathered rounded
    ///rects `mask` builds over `frames`). The invite flight flies images, never live shaders —
    ///so the title's halo can only ride the open as pre-rendered pixels; the live view then
    ///replaces it pixel-aligned under the pager reveal. Returns the bottom `bakedStripHeight`
    ///points of the slot, to be pinned bottomLeading at destination size.
    static func bakedHalo(for image: UIImage, slot: CGSize, frames: [CGRect], scale: CGFloat) -> UIImage? {
        guard slot.width > 0, slot.height > 0, image.size.width > 0, image.size.height > 0 else { return nil }

        //The photo aspect-filled into the slot, as Color.clear.overlay + scaledToFill draws it.
        //Standard range, like the band bake: extended/P3 through the default CIContext
        //gamut-shifts against the live pipeline.
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.preferredRange = .standard
        let fillScale = max(slot.width / image.size.width, slot.height / image.size.height)
        let fillSize = CGSize(width: image.size.width * fillScale, height: image.size.height * fillScale)
        let fillOrigin = CGPoint(x: (slot.width - fillSize.width) / 2, y: (slot.height - fillSize.height) / 2)
        let flat = UIGraphicsImageRenderer(size: slot, format: format).image { _ in
            image.draw(in: CGRect(origin: fillOrigin, size: fillSize))
        }
        guard let photo = flat.cgImage else { return nil }

        //The mask, drawn exactly as `mask` lays it out (inset, r12, +2pt nudge), feathered by
        //the same 4pt blur
        let maskFlat = UIGraphicsImageRenderer(size: slot, format: format).image { ctx in
            UIColor.white.setFill()
            for frame in frames {
                let dy = min(8, max((frame.height - 12) / 2, 0))
                let rect = frame.insetBy(dx: 0, dy: dy).offsetBy(dx: 0, dy: 2)
                UIBezierPath(roundedRect: rect, cornerRadius: haloCornerRadius).fill()
            }
        }
        guard let maskImage = maskFlat.cgImage else { return nil }

        let extent = CGRect(x: 0, y: 0, width: slot.width * scale, height: slot.height * scale)

        //UNCLAMPED, deliberately: SwiftUI's .blur samples transparency beyond the layer, so
        //the live halo's alpha falls off toward the slot edges — the bake must match or the
        //reveal crossfade brightens the corners
        let photoBlur = CIFilter.gaussianBlur()
        photoBlur.inputImage = CIImage(cgImage: photo)
        photoBlur.radius = Float(40 * scale)

        let maskBlur = CIFilter.gaussianBlur()
        maskBlur.inputImage = CIImage(cgImage: maskImage)
        maskBlur.radius = Float(haloBlurRadius * scale)

        let blend = CIFilter.blendWithMask()
        blend.inputImage = photoBlur.outputImage?.cropped(to: extent)
        blend.backgroundImage = CIImage(color: .clear).cropped(to: extent)
        blend.maskImage = maskBlur.outputImage?.cropped(to: extent)

        //CI's origin is bottom-left: the slot's visual bottom strip is y 0..strip
        let strip = CGRect(x: 0, y: 0, width: slot.width * scale, height: bakedStripHeight * scale)
        guard let output = blend.outputImage?.cropped(to: strip),
              let baked = bakeContext.createCGImage(output, from: strip) else { return nil }
        return UIImage(cgImage: baked, scale: scale, orientation: .up)
    }
}
