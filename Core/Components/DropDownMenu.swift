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
    
    init(width: CGFloat = 325, @ViewBuilder content: @escaping () -> Content){
        self.width = width
        self.content = content
    }
    
    var body: some View {
        
        VStack(spacing: 18) {
            content()
        }
        .padding(24)
        .frame(width: width)
        .cornerRadius(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.background)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
        )
        .font(.body(18))
    }
}

struct customRow : View {
    let image: String?
    let text: String
    var body: some View {
        HStack (spacing: 24) {
            if let emoji = image {
               Text(emoji)
            }
            Text(text)
            Spacer()
        }
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


