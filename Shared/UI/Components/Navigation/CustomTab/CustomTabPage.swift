//
//  GenericScrollScreen.swift
//  Scoop
//
//  Created by Art Ostin on 08/12/2025.
//

import SwiftUI

struct CustomTabPage<Content: View>: View {
    
    @State var scrollViewOffset: CGFloat = 0
    @Binding var TabAction: Bool
    
    let page: Page
    let content: Content
    
    init(page: Page, TabAction: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.page = page
        _TabAction = TabAction
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                ZStack(alignment: .top) {
                    TabButton(page: page, isPresented: $TabAction)
                        .padding(.top, 12)
                    TabTitle(page: page, offset: $scrollViewOffset)
                        .padding(.top, 60)
                }
                content
            }
            .padding(.bottom, 48)
        }
        .overlay(alignment: .top) {scrollNavBar}
        .scrollIndicators(.never)
        .coordinateSpace(name: page)
        .onPreferenceChange(TitleOffsetsKey.self) { value in
            scrollViewOffset = value[page] ?? 0
        }
        .colorBackground()
    }
    private var scrollNavBar: some View {
        GeometryReader { geo in
            ScrollNavBar(title: page.title, topSafeArea: geo.safeAreaInsets.top)
                .opacity(withAnimation(.easeInOut(duration: 0.2)) { scrollViewOffset < 0 ? 1 : 0 })
                .ignoresSafeArea(edges: .all)
        }
    }
}
