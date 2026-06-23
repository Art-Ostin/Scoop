//
//  MeetInfoSection1.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/05/2026.
//

import SwiftUI

struct MeetInfoCoverScrollView: View {
    @State private var scrollProgress: Double = 0

    var body: some View {

        VStack(spacing: 24) {
            Text("1. Invite")
                .font(.title(24, .bold))

            scrollView

            AnimatedPageIndicator(
                count: Event.EventType.allCases.count,
                progress: scrollProgress)
        }
    }
}

extension MeetInfoCoverScrollView {

    private var scrollView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(Event.EventType.allCases, id: \.self) {type in
                    scrollSection(type: type)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: Double.self) { geo in
            let width = geo.containerSize.width
            return width > 0 ? geo.contentOffset.x / width : 0
        } action: { _, newValue in
            scrollProgress = newValue
        }
    }
    
    func scrollSection(type: Event.EventType) -> some View {
        VStack(spacing: 16) {
            Image(type.image)
                .resizable()
                .frame(width: 180, height: 180)
            
            (
            Text("\(type.longTitle): ")
                .font(.body(15, .medium))
            
            +
            Text(type.howItWorks)
                .font(Font.body(14, .regular))
            )
            .multilineTextAlignment(.center)
            .lineSpacing(4)
        }
        .padding(.horizontal, 24)
    }
}
