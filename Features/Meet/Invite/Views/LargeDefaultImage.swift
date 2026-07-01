//
//  LargeDefaultImage.swift
//  Scoop Test
//
//  Created by Art Ostin on 30/06/2026.
//

import SwiftUI

struct LargeDefaultImage: View {
    let image: UIImage

    /// height = `heightRatio` × width. Bigger = the art reaches further down.
    /// Apple's hero fades out around 1.7× the width.
    private let heightRatio: CGFloat = 1.7

    var body: some View {

        Color.clear
            .aspectRatio(1 / heightRatio, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .frame(maxWidth: .infinity)
            .clipped()
    }
}
