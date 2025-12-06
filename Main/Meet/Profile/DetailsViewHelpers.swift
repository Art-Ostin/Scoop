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

struct InfoItem: View {
    let image: String
    let info: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            //Overlay method, ensures all images take up same space
            Rectangle()
                .fill(Color.clear)
                .frame(width: 20, height: 17)
                .overlay {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                }
            
            Text(info)
                .font(.body(17, .medium))
        }
    }
}

struct NarrowDivide: View {
    var body: some View {
        Rectangle()
            .foregroundColor(.clear)
            .frame(width: 0.7, height: 16)
            .background(Color(red: 0.9, green: 0.9, blue: 0.9))
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { start in
            Array(self[start..<Swift.min(start + size, count)])
        }
    }
}
