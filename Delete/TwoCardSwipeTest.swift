//
//  TwoCardSwipeTest.swift
//  Scoop
//
//  Created by Art Ostin on 07/04/2026.
//

/*
 
 import SwiftUI

 struct TwoCardSwipeTest: View {
     private let peek: CGFloat = 82
     private let spacing: CGFloat = 16

     var body: some View {
         GeometryReader { proxy in
             let cardWidth = proxy.size.width - (peek * 2)

             ScrollView(.horizontal) {
                 HStack(spacing: spacing) {
                     card(isCard1: true)
                         .frame(width: cardWidth)

                     card(isCard1: false)
                         .frame(width: cardWidth)
                 }
                 .scrollTargetLayout()
                 .frame(maxHeight: .infinity, alignment: .center)
             }
             .safeAreaPadding(.horizontal, peek)
             .scrollTargetBehavior(.viewAligned)
             .scrollIndicators(.hidden)
         }
     }
 }

 extension TwoCardSwipeTest {
     private func card(isCard1: Bool) -> some View {
         Text(isCard1 ? "Hello World" : "Goodbye World")
             .frame(maxWidth: .infinity)
             .frame(height: isCard1 ? 300 : 400)
             .background(
                 RoundedRectangle(cornerRadius: 24)
                     .foregroundStyle(Color.background)
                     .overlay {
                         RoundedRectangle(cornerRadius: 24)
                             .stroke(.blue, lineWidth: 1)
                     }
             )
             .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 4)
             .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                 let progress = 1 - min(abs(phase.value), 1)
                 let scale = CGFloat(0.5 + progress * 0.5)

                 return content.scaleEffect(scale, anchor: .center)
             }
     }
 }

 */
