//
//  TabViewModifiers.swift
//  Scoop
//
//  Created by Art Ostin on 27/10/2025.
//

import SwiftUI


 struct TabViewModifiers: ViewModifier {
     let page: Page
     @Binding var scrollViewOffset: CGFloat
     
     func body(content: Content) -> some View {
         content
             .overlay(alignment: .top) {
                 ScrollNavBar(title: page.rawValue, topSafeArea: 5)
                     .opacity(scrollViewOffset < 0 ? 1 : 0)
                     .ignoresSafeArea(edges: .all)
             }
             .scrollIndicators(.never)
             .onPreferenceChange(TitleOffsetsKey.self) { value in
                 scrollViewOffset = value[page] ?? 0
             }
             .coordinateSpace(name: page)
     }
 }

 extension View {
     func tabViewModifiers(page: Page, scrollViewOffset: Binding<CGFloat>) -> some View {
         self.modifier(TabViewModifiers(page: page, scrollViewOffset: scrollViewOffset))
     }
 }

