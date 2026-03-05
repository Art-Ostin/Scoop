//
//  TypeMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct TypeMessageView: View {
    var body: some View {
        HStack (alignment: .bottom, spacing: 6) {
            
            TextField("Message...", text: $text, axis: .vertical)
                .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassIfAvailable(RoundedRectangle(cornerRadius: 24), isClear: false)
                .lineSpacing(4)
                .focused($isFocused)
                .lineLimit(1...5)
        
            Button {
                print("Hello World")
            } label: {
                ZStack {
                    Circle()
                        .fill(text.isEmpty ? Color.grayBackground : Color.accent)
                    
                    Image("SendArrow")
                        .scaleEffect(0.8)
                }
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(text.isEmpty ? 0 : 0.1), radius: 3, y: 2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.horizontal)
        .padding(.bottom, isFocused ? 12 : 0)
    }
}

#Preview {
    TypeMessageView()
}
