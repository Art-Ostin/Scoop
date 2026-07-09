//
//  ScaledScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.

import SwiftUI

struct ImageCarousel: View {
    // Content
    let images: [UIImage]

    // Geometry
    let hPadding: CGFloat
    let topRadius: CGFloat
    let bottomRadius: CGFloat
    let aspectRatio: CGFloat

    // Cosmetic
    let showShadow: Bool

    // Optional scroll wiring
    @Binding var scrollProgress: Double
    @Binding var scrollPosition: ScrollPosition

    init(
        images: [UIImage],
        hPadding: CGFloat,
        topRadius: CGFloat,
        bottomRadius: CGFloat,
        aspectRatio: CGFloat = 1 / 1.12,
        showShadow: Bool = false,
        scrollProgress: Binding<Double> = .constant(0),
        scrollPosition: Binding<ScrollPosition> = .constant(.init(edge: .leading))
    ) {
        self.images = images
        self.hPadding = hPadding
        self.topRadius = topRadius
        self.bottomRadius = bottomRadius
        self.aspectRatio = aspectRatio
        self.showShadow = showShadow
        self._scrollProgress = scrollProgress
        self._scrollPosition = scrollPosition
    }
        
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
        .scrollPosition($scrollPosition)
        .scrollClipDisabled()//So shadow not cut off
    }
    
    private func carouselImage(_ image: UIImage) -> some View {
        GreedyImage(aspectRatio: aspectRatio, image: image)
            .clipShape(.rect(
                topLeadingRadius: topRadius,
                bottomLeadingRadius: bottomRadius,
                bottomTrailingRadius: bottomRadius,
                topTrailingRadius: topRadius,
                style: .continuous
            ))
            .padding(.horizontal, hPadding) //Critical padding goes before container Relative frame
            .containerRelativeFrame(.horizontal)
            .cardShadow(showShadow: showShadow)
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
