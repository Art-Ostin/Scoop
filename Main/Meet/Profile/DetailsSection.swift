//
//  DetailsSection.swift
//  Scoop
//
//  Created by Art Ostin on 03/12/2025.
//


import SwiftUI

struct DetailsSection<Content: View>: View {
    let color: Color
    let content: Content
    
    init(color: Color = Color(red: 0.9, green: 0.9, blue: 0.9), @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 185, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear)
                .stroke(20, lineWidth: 1, color: color)
        )
        .padding(.horizontal, 16)
        .ignoresSafeArea(edges: .top)
    }
}

struct PromptView: View {
    let prompt: PromptResponse
    var count: Int {prompt.response.count}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(prompt.prompt)
                .font(.body(14, .italic))
            
            Text(prompt.response)
                .font(.title(24, .bold))
                .lineSpacing(8)
                .font(.title(28))
                .lineLimit( count > 90 ? 4 : 3)
                .minimumScaleFactor(0.6)
                .lineSpacing(8)
        }
    }
}

