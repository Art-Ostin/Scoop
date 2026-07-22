//
//  ImageElements.swift
//  Scoop
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI

//A single, screen-inset app image. Carousel page geometry lives in ImageCarousel.
struct ScoopImage: View {
    let image: UIImage

    var aspectRatio: AspectRatio = .default
    var cornerRadius: CGFloat = CornerRadius.image
    var zoomSourceID: String? = nil //UIKit-backs the image so ImageZoom can fly a screen out of it

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio.ratio, contentMode: .fit)
            .overlay { imageContent }
            .clipShape(.rect(cornerRadius: cornerRadius))
        
            //So overlay content fits on the image shrink width to fit scren
            .containerRelativeFrame(.horizontal) { length, _ in
                return max(length - Spacing.gutter * 2, 0)
            }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let zoomSourceID {
            ZoomSourceImage(id: zoomSourceID, image: image, cornerRadius: cornerRadius)
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        }
    }
}


struct ImageCarouselInvite: View {
    
    //Injected
    let images: [UIImage]
    let aspectRatio: AspectRatio
    let confirmScreen: Bool
    
    //Local
    @State var scrollProgress: Double = 0

    var body: some View {
        PagerScrollView(progress: $scrollProgress) {
            ForEach(images, id: \.self) { image in
                scrollImage(image)
            }
        }
        .scrollClipDisabled() //Pages bleed past the gutter mid-scroll; the parent card mask cuts them]
        .overlay(alignment: .bottom) { pageIndicator }
    }
    
    private func scrollImage(_ image: UIImage) -> some View {
        Color.clear
            .aspectRatio(aspectRatio.ratio, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .containerRelativeFrame(.horizontal)
    }
    
    private var pageIndicator: some View {
        ImagePageIndicator(count: 6, progress: scrollProgress, activeColor: .white)
            .scaleEffect(0.7)
            .padding(.bottom, Spacing.xs)
            .opacityPop(visible: !confirmScreen)
    }
}







struct CardImageCarousel: View {
    let images: [UIImage]
    let imagePadding: CGFloat = 3
    
    var topRadius: CGFloat { CornerRadius.concentric(in: CornerRadius.image, inset: 3)}
    
    //Drives the built-in page indicator
    @Binding var scrollProgress: Double
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            ImageCarousel(
                images: images,
                pageInset: imagePadding,
                topRadius: topRadius,
                bottomRadius: CornerRadius.sm,
                aspectRatio: AspectRatio.card,
                scrollProgress: $scrollProgress,
                scrollPosition: .constant(ScrollPosition())
            )
            .overlay(alignment: .bottom) {
                ImagePageIndicator(count: images.count, progress: scrollProgress)
                    .scaleEffect(0.7)
                    .offset(y: 12)
            }
            .padding(.top, imagePadding)
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






/*
 .customHorizontalScrollFade(width: 3, showFade: showFade, fromLeading: true)
 .customHorizontalScrollFade(width: 3, showFade: showFade, fromLeading: false)
 */

/*
 

 @ViewBuilder
 private func imagePage(_ image: UIImage, index: Int) -> some View {
     let page = CarouselImage(
         image: image,
         aspectRatio: aspectRatio,
         radii: .init(top: topRadius, bottom: bottomRadius),
         pageInset: pageInset,
         fillsContainerHeight: fillsContainerHeight
     )
     if let onImageTap {
         page.contentShape(Rectangle()).onTapGesture { onImageTap(index) }
     } else {
         page
     }
 }

 private struct CarouselImage: View {
     let image: UIImage
     let aspectRatio: AspectRatio
     let radii: RectangleCornerRadii
     let pageInset: CGFloat
     let fillsContainerHeight: Bool

     var body: some View {
         base
             .overlay {
                 Image(uiImage: image)
                     .resizable()
                     .scaledToFill()
             }
             .clipShape(.rect(cornerRadii: radii))
             .padding(.horizontal, pageInset)
             .containerRelativeFrame(.horizontal) { length, _ in
                 length.isFinite ? length : 0
             }
     }

     @ViewBuilder
     private var base: some View {
         if fillsContainerHeight {
             Color.clear
         } else {
             Color.clear.aspectRatio(aspectRatio.ratio, contentMode: .fit)
         }
     }
 }
 */
