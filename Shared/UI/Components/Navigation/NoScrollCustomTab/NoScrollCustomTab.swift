//
//  NoScrollCustomTab.swift
//  Scoop
//
//  Created by Art Ostin on 17/03/2026.
//

import SwiftUI

struct NoScrollCustomTab<Content: View>: View {

    @Binding var tabAction: Bool
    
    let page: Page
    let content: Content
    
    init(page: Page, tabAction: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.page = page
        _tabAction = tabAction
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 36) {
            title
            content
        }
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16) //On the Screens
        .background(Color.background)
    }
    
    private var title: some View {
        Text(page.title)
            .font(.custom("SFProRounded-Bold", size: 32))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
