//
//  ImageContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import SwiftUI

struct imageContainer<Overlay: View>: View {
    
    let image: UIImage
    let size: CGFloat
    let shadow: CGFloat
    @ViewBuilder var overlay: () -> Overlay
    
    init(image: UIImage, size: CGFloat, shadow: CGFloat = 5, @ViewBuilder overlay: @escaping () -> Overlay = {EmptyView()}) {
        self.image = image
        self.size = size
        self.shadow = shadow
        self.overlay = overlay
    }
    
    var body: some View {
        
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: shadow)
            .overlay(alignment: .bottomTrailing) {
                overlay()
                    .padding(24)
            }
    }
}
