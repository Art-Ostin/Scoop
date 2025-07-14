//
//  DropDownMenu.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct DropDownMenu<Content: View> : View {
    
    let content: () -> Content
    var width: CGFloat = 325
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
        
        VStack(spacing: 18) {
            content()
        }
        .padding( [.top, .bottom, .leading], 24)
        .frame(width: width)
        .background(Color.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
        .font(.body(18))
    }
}

struct customRow : View {
    
    let image: String?
    let text: String
    var body: some View {
        HStack (spacing: 24) {
            if let image = image {
               Image(image)
            }
            Text(text)
            Spacer()
        }
    }
}

