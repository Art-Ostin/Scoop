//
//  ImageContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import SwiftUI




struct ImageModifier: ViewModifier {
    
    let size: CGFloat
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

extension View {
    func defaultImage(_ size: CGFloat, _ radius: CGFloat = 18) -> some View { modifier(ImageModifier(size: size, radius: radius)) }
}





// Try and get rid of Image Container 



struct imageContainer<Overlay: View>: View {
    
    @State var currentAmount: CGFloat = 0
    
    let image: UIImage?
    let size: CGFloat
    @State var shadow: CGFloat
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
            .scaleEffect(1 + currentAmount)
            .gesture (
                MagnificationGesture()
                    .onChanged{ value in
                        currentAmount = value - 1
                    }
            )
            .overlay(alignment: .bottomTrailing) {
                overlay()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
            }
    }
}
