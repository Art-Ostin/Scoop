//
//  OptionCellNoCount.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct OptionPill: View {
    
    
    let title: String
    var width: CGFloat = 148
    
    @Binding var isSelected: String?
    
    var onTap: (() -> Void)
    
    @Binding private var counter: Int
    
    init(
        title: String,
        counter: Binding<Int> = .constant(0),
        width: CGFloat = 148,
        isSelected: Binding<String?>,
        onTap: @escaping () -> Void
    
    ) {
        self.title = title
        self._counter = counter
        self.width = width
        self._isSelected = isSelected
        self.onTap = onTap
        
    }

    var body: some View {
        
        let isSelected: Bool = (title == self.isSelected)
        
        Text(title)
            .frame(width: width, height: 44)
            .background (isSelected ? Color.accentColor : Color.grayBackground, in: RoundedRectangle(cornerRadius: 20))
            .font(.body(16, .bold))
            .foregroundStyle(isSelected ? Color.white : Color.black)
            .onTapGesture {
                self.isSelected = title
                onTap()
                withAnimation {
                    counter += 1
                }
            }
    }
}

#Preview {
    OptionPill(title: "Sex", isSelected: .constant("Sex"), onTap: {})
}

