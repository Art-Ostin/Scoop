//
//  PageSwipeTest2.swift
//  Scoop
//
//  Created by Art Ostin on 26/10/2025.
//

import SwiftUI

struct PageSwipeTest2: View {
    
    let images = ["CoolGuys", "DancingCats"]
    let peek: CGFloat = 78
    
    var body: some View {
        
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(images.indices, id: \.self) { index in
                    Image(images[index])
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .containerRelativeFrame(.horizontal, count: 1, spacing: peek)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.7)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, peek)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.never)
    }
}

#Preview {
    PageSwipeTest2()
}
