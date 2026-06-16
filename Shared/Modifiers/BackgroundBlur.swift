//
//  BackgroundBlur.swift
//  Scoop Test
//
//  Created by Art Ostin on 10/06/2026.
//

import SwiftUI

//To blur behind the images in the app
struct BackgroundBlur: View {

    let image: UIImage
    let size: CGFloat
    let frames: [CGRect]
    var clipCornerRadius: CGFloat = 22
    var maskCornerRadius: CGFloat = 12

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: max(size, 0), height: max(size, 0))
            .blur(radius: 22)
            .mask(mask)
            .clipShape(.rect(cornerRadius: clipCornerRadius))
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
            let rect = frame.insetBy(dx: -4, dy: 4)
            RoundedRectangle(cornerRadius: maskCornerRadius)
                .frame(width: max(rect.width, 0), height: max(rect.height, 0))
                .position(x: rect.midX, y: rect.midY)
                .blur(radius: 4)
        }
    }
}

#Preview {
    BackgroundBlur(
        image: UIImage(systemName: "photo.fill") ?? UIImage(),
        size: 300,
        frames: [CGRect(x: 24, y: 230, width: 180, height: 40)]
    )
    .frame(width: 300, height: 300)
}
