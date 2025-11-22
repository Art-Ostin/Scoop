//
//  OptionCellNoCount.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct OptionPill: View {
    
    let title: String
    @Binding var isSelected: String?
    let width: CGFloat
    var onTap: () -> Void
    
    init(title: String, width: CGFloat = 148, isSelected: Binding<String?>, onTap: @escaping () -> ()) {
        self.title = title
        self._isSelected = isSelected
        self.width = width
        self.onTap = onTap
    }
    
    var body: some View {
        
        let selected = title == isSelected
        
        Text(title)
            .frame(width: width, height: 44)
            .background (selected ? Color.accentColor : Color.grayBackground, in: RoundedRectangle(cornerRadius: 20))
            .font(.body(16, .bold))
            .foregroundStyle(selected ? Color.white : Color.black)
            .onTapGesture {
                self.isSelected = title
                onTap()
            }
    }
}

#Preview {
    OptionPill(title: "Sex", isSelected: .constant("Sex"), onTap: {})
}


struct SexStandardPill: View {
    
    let title: String

    @Binding var selectedOption: String
    
    var isSelected: Bool {
        title == selectedOption
    }
    var onTap: () -> Void
    
    var body: some View {
        Text(title)
            .frame(width: 148, height: 44)
            .background (isSelected ? Color.accentColor : Color.grayBackground, in: RoundedRectangle(cornerRadius: 20))
            .font(.body(16, .bold))
            .foregroundStyle(isSelected ? Color.white : Color.black)
            .onTapGesture {
                selectedOption = title
                onTap()
            }
    }
}

struct SexOptionPill: View {
    
    @Binding var gender: String
    @Binding var editText: Bool
    
    var body: some View {
        
        HStack(spacing: 16) {
            Text(gender)
                .font(.body(16, .bold))
                .padding(.horizontal, 24)
                .frame(width: 148, height: 44)
                .stroke(20, lineWidth: 2, color: .accent)
                .overlay(alignment: .topTrailing) {
                    Image("EditButton")
                        .scaleEffect(0.7)
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.background)
                        )
                        .offset(x: 4, y: -4)
                }
                .onTapGesture { editText = true }
                .frame(maxWidth: .infinity)
        }
    }
}
