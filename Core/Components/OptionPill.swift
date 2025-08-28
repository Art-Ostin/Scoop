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

