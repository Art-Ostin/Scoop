//
//  ImageContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import SwiftUI

struct imageContainer<Overlay: View>: View {
    
    let image: UIImage?
    let size: CGFloat
    let shadow: CGFloat
    let url: URL?
    @ViewBuilder var overlay: () -> Overlay
    
    init(image: UIImage? = nil, size: CGFloat, shadow: CGFloat = 5, @ViewBuilder overlay: @escaping () -> Overlay = {EmptyView()}, url: URL? = nil) {
        self.image = image
        self.size = size
        self.shadow = shadow
        self.overlay = overlay
        self.url = url
    }
    
    @ViewBuilder private var content: some View {
        if let url {
            AsyncImage(url: url) { image in
                image
                    .resizable()
            } placeholder: {
                ProgressView()
            }
        } else if let image = image {
            Image(uiImage: image).resizable()
        }
    }
    
    var body: some View {
        content
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
            .shadow(color: shadow != 0 ?.black.opacity(0.2) : .clear, radius: 4, x: 0, y: shadow)
            .overlay(alignment: .bottomTrailing) {
                overlay()
                    .padding(24)
            }
    }
}
