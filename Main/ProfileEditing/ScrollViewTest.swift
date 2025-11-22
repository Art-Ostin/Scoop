//
//  ScrollViewTest.swift
//  Scoop
//
//  Created by Art Ostin on 21/11/2025.
//

/*
 
 import SwiftUI

 struct ScrollViewTest: View {
     private let itemCount = 40
     
     @State private var scrollOffset: CGFloat = 0
     @State private var contentHeight: CGFloat = 0
     @State private var scrollViewHeight: CGFloat = 0
     
     // Which item is currently at the scroll position (near the top by default)
     private var progress: CGFloat {
         guard contentHeight > 0, scrollViewHeight > 0 else { return 0 }
         let maxOffset = max(contentHeight - scrollViewHeight, 0)
         if maxOffset == 0 {
             // Content fits without scrolling – treat as 100%
             return 1
         }
         let p = scrollOffset / maxOffset
         return min(max(p, 0), 1)   // clamp to 0...1
     }
     
     
     var body: some View {
         VStack {
             Text("\(Int(progress * 100)) %")
                 .font(.title)
             
             ScrollView {
                 
                 GeometryReader { proxy in
                      let offset = -proxy.frame(in: .named("scroll")).minY
                      Color.clear
                          .preference(key: ScrollOffsetKey.self, value: offset)
                  }
                  .frame(height: 0)
                 LazyVStack(spacing: 0) {
                     ForEach(0..<itemCount, id: \.self) { index in
                         Rectangle()
                             .frame(width: 45, height: 45)
                             .id(index)           // needed for scrollPosition
                     }
                 }
                 .background(
                     GeometryReader { proxy in
                         Color.clear
                             .preference(key: ContentHeightKey.self,
                                         value: proxy.size.height)
                     }
                 )
             }
             .coordinateSpace(name: "scroll")
             .background(
                 GeometryReader { proxy in
                     Color.clear
                         .preference(key: ScrollViewHeightKey.self,
                                     value: proxy.size.height)
                 }
             )
         }
         .padding()
         .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
         .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
         .onPreferenceChange(ScrollViewHeightKey.self) { scrollViewHeight = $0 }
     }
 }

 #Preview {
     ScrollViewTest()
 }

 */


