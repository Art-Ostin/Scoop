//
//  DetailsInfo.swift
//  Scoop
//
//  Created by Art Ostin on 02/11/2025.
//

import SwiftUI

struct DetailsInfo<Content: View>: View {
    
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.body(13, .italic))
                .foregroundStyle(Color.grayText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 10) {
                content
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .stroke(12, lineWidth: 1, color: .grayPlaceholder)
        }
    }
}

