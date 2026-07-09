//
//  ImageScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.

import SwiftUI

struct ImageCarousel: View {
    let images: [UIImage]

    // Geometry
    let hPadding: CGFloat
    let topRadius: CGFloat
    let bottomRadius: CGFloat
    var aspectRatio: CGFloat = 1 / 1.12

    @Binding var scrollProgress: Double
    @Binding var scrollPosition: ScrollPosition
    
    
    
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(images, id: \.self) { image in
                    carouselImage(image)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .trackScrollProgress(scrollProgress: $scrollProgress)
        .scrollClipDisabled() //Pages bleed past the gutter mid-scroll; the parent card mask cuts them
    }

    private func carouselImage(_ image: UIImage) -> some View {
        GreedyImage(image: image, hPadding: hPadding, aspectRatio: aspectRatio)
            .clipShape(.rect(
                topLeadingRadius: topRadius,
                bottomLeadingRadius: bottomRadius,
                bottomTrailingRadius: bottomRadius,
                topTrailingRadius: topRadius,
                style: .continuous
            ))
    }
}


/*
 struct HorizontalScrollView<Content: View>: View {
     var peek: CGFloat = 0
     @ViewBuilder var content: Content

     var body: some View {
         ScrollView(.horizontal) {
             HStack(spacing: 0) {
                 content
             }
             .scrollTargetLayout()
         }
         .contentMargins(.horizontal, peek, for: .scrollContent)
         .scrollTargetBehavior(.paging)
         .scrollIndicators(.hidden)
     }
 }

 extension View {
     @ViewBuilder
     func horizontalScrollSlot(id: some Hashable, shrinkAnchor: UnitPoint? = nil) -> some View {
         let page = self
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .containerRelativeFrame(.horizontal)
             .id(id)

         if let shrinkAnchor {
             page.pageScrollTransition(anchor: shrinkAnchor)
         } else {
             page
         }
     }

     func pageScrollTransition(anchor: UnitPoint, yOffset: CGFloat = 0) -> some View {
         scrollTransition(.interactive, axis: .horizontal) { content, phase in
             let progress = 1 - min(abs(phase.value), 1)
             let scale = 0.5 + progress * 0.5
             return content
                 .scaleEffect(scale, anchor: anchor)
                 .offset(y: (1 - progress) * yOffset)
         }
     }
 }

 */
