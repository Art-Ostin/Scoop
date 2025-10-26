//
//  PageSwipeTest.swift
//  Scoop
//
//  Created by Art Ostin on 26/10/2025.
//

import SwiftUI

struct PageSwipeTest: View {
    
    let images = ["CoolGuys", "DancingCats"]
    let peek: CGFloat  = 68
    var body: some View {
        ScrollView(.horizontal) {
          HStack(spacing: 0) {
              ForEach(images, id: \.self) {image in
                  Image(image)
                      .resizable()
                      .scaledToFit()
                      .frame(height: 200)
                      .containerRelativeFrame(.horizontal, count: 1, spacing: peek)
              }
          }
          .scrollTargetLayout()
        }
        .contentMargins(.horizontal, peek)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
    }
}

#Preview {
    PageSwipeTest()
}
