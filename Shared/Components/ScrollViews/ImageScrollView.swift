//
//  ImageScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.

import SwiftUI




struct CardImageScrollView: View {
    
    let images: [UIImage]
    let imagePadding: CGFloat = 3
    
    
    static var topRadius: CGFloat { CornerRadius.concentric(in: parentCornerRadius, inset: imagePadding) }

    
    //Injected (scrollProgress: pass a binding when the parent tracks paging, e.g. InviteImageCarousel's blur)
    var scrollProgress: Binding<Double>? = nil

    //Local view state
    @State private var internalProgress: Double = 0
    
    var topRadius: CGFloat { CornerRadius.concentric(in: 24, inset: 3)}
    
    
    

    private var progress: Binding<Double> { scrollProgress ?? $internalProgress }

    var body: some View {
        VStack(spacing: 8) {
            ImageCarousel(
                images: images,
                hPadding: Self.imagePadding,
                topRadius: topRadius,
                bottomRadius: CornerRadius.sm,
                aspectRatio: AspectRatio.card,
                scrollProgress: progress,
                scrollPosition: .constant(ScrollPosition())
            )
            AnimatedPageIndicator(count: images.count, progress: progress.wrappedValue)
                .scaleEffect(0.7, anchor: .top)
        }
        .padding(.top, Self.imagePadding) //Horizontal padding applied inside ImageCarousel
    }
}





//Free-page pager. Still used by RespondContainer; ImageCarousel replaces it for image paging.
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
        .pagedScroll()
    }
}


extension View {
    @ViewBuilder
    func pagedScroll(progress: Binding<Double>? = nil) -> some View {
        let base = self
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
        if let progress {
            base.trackScrollProgress(scrollProgress: progress)
        } else {
            base
        }
    }
}

extension View {
    //Shared pager defaults. .paging over .viewAligned is deliberate: viewAligned settles too soft.
    //Position tracking and clip behaviour vary per pager, so they stay at the call site.

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
