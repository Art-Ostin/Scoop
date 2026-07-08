//
//  BackgroundBlur.swift
//  Scoop
//
//  Created by Art Ostin on 10/06/2026.
//

import SwiftUI

//To blur behind the images in the app
struct BackgroundBlur: View {

    //Shared with SendInviteCard's flight halo, which re-creates this treatment
    //on animated anchors — keep the two in lockstep via these constants.
    static let imageBlurRadius: CGFloat = 22
    static let haloWidthOutset: CGFloat = 4 //Halo extends this far past the text on each side
    static let haloCornerRadius: CGFloat = 12
    static let haloBlurRadius: CGFloat = 4

    let image: UIImage
    let size: CGSize
    let frames: [CGRect]
    var clipCornerRadius: CGFloat = 22
    var maskCornerRadius: CGFloat = Self.haloCornerRadius
    //Halo tightness: how much each frame shrinks vertically before blurring — raise to shorten.
    var verticalInset: CGFloat = 4

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: max(size.width, 0), height: max(size.height, 0))
            .blur(radius: Self.imageBlurRadius)
            .mask(mask)
            .clipShape(.rect(cornerRadius: clipCornerRadius, style: .continuous))
            .allowsHitTesting(false)
    }

    private var mask: some View {
        ZStack {
            ForEach(Array(frames.enumerated()), id: \.offset) { _, frame in
                halo(for: frame)
            }
        }
    }

    @ViewBuilder
    private func halo(for frame: CGRect) -> some View {
        if frame != .zero {
            let rect = frame.insetBy(dx: -Self.haloWidthOutset, dy: verticalInset)
            RoundedRectangle(cornerRadius: maskCornerRadius)
                .frame(width: max(rect.width, 0), height: max(rect.height, 0))
                .position(x: rect.midX, y: rect.midY)
                .blur(radius: Self.haloBlurRadius)
        }
    }
}

#Preview {
    BackgroundBlur(
        image: UIImage(systemName: "photo.fill") ?? UIImage(),
        size: CGSize(width: 300, height: 300),
        frames: [CGRect(x: 24, y: 230, width: 180, height: 40)]
    )
    .frame(width: 300, height: 300)
}
