//
//  ImageElements.swift
//  Scoop
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI


enum AppImageType {case meet, invite}

struct AppImage: View {

    let type: AppImageType
    var aspectRatio: CGFloat { type == .meet ? 1/1.12 : 1.55}
        
    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                Image("Image3")
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: 20))
            .containerRelativeFrame(.horizontal) { length, _ in
                return max(length - 16 * 2, 0)
            }//No padding but this method so overlay content works
            .cardShadow(type: type)
    }
}


enum imageCarouselType { case profile, invite}

struct ImageCarousel: View {
    
    //Properties Imported
    let images: [UIImage]
    let type: imageCarouselType
    let aspectRatio: CGFloat
    
    //Values change based of type
    var hPadding: CGFloat { type == .invite ? 0 : 8 }
    var showIndicator: Bool { type == .invite ? true : false }
    var cornerRadius: CGFloat { type == .invite ? 0 : 20 }
    
    @State private var scrollProgress: Double = 0
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(images, id: \.self) { image in
                    profileImage(image)
                }
            }
            .scrollTargetLayout()
            .overlay(alignment: .bottom) { scrollIndicator}
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
    }
    
    private func profileImage(_ profileImage: UIImage) -> some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .padding(.horizontal, hPadding)
            .containerRelativeFrame(.horizontal)
    }
    
    @ViewBuilder
    private var scrollIndicator: some View {
        if showIndicator {
            ImagePageIndicator(count: 6, progress: scrollProgress, activeColor: .white)
                .scaleEffect(0.7)
                .padding(.bottom, Spacing.xs)
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
