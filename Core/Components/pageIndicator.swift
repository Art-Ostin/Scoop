//
//  pageIndicator.swift
//  Scoop
//
//  Created by Art Ostin on 03/12/2025.
//

import SwiftUI

struct PageIndicator: View {
    let count: Int
    let selection: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                let isSelected = index == selection
                
                RoundedRectangle(cornerRadius: 100)
                    .frame(width: isSelected ? 10 : 5, height: 5)
                    .foregroundStyle(isSelected ? .black : .clear)
                    .stroke(100, lineWidth: 1, color: isSelected ? .clear : .black)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.background)
                .shadow(color: .black.opacity(0.05), radius: 1.5, x: 0, y: 3)
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    PageIndicator(count: 5, selection: 3)
}
