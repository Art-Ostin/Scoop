//
//  DropDownMenu.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct DropDownMenu<Content: View> : View {
    
    let content: () -> Content
    var width: CGFloat
    let cornerRadius: CGFloat
    let bottomPadding: CGFloat
    
    init(width: CGFloat = 325, cornerRadius: CGFloat = 12, bottomPadding: CGFloat = 24, @ViewBuilder content: @escaping () -> Content){
        self.width = width
        self.content = content
        self.cornerRadius = cornerRadius
        self.bottomPadding = bottomPadding
    }
    
    var body: some View {
        VStack(spacing: 18) {
            content()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, bottomPadding)
        .frame(width: width)
        .cornerRadius(12)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.background)
        )
        .font(.body(18))
    }
}


struct SoftDivider: View {
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .frame(maxWidth:.infinity)
            .foregroundStyle(Color(red: 0.94, green: 0.94, blue: 0.94))
    }
}


