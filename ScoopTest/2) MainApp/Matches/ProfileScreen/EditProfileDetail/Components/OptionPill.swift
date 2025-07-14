//
//  OptionCellNoCount.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI


import SwiftUI

struct OptionPill: View {
    
    let title: String
    var width: CGFloat = 148
    @Binding var isSelected: String?
    
    var onTap: (() -> Void)
    
    var body: some View {
        
        let isSelected: Bool = (title == self.isSelected)
        
        Text(title)
            .frame(width: width, height: 44)
            .background (isSelected ? Color.accentColor : Color.grayBackground, in: RoundedRectangle(cornerRadius: 20))
            .font(.body(16, .bold))
            .foregroundStyle(isSelected ? Color.white : Color.black)
            .onTapGesture {
                self.isSelected = title
            }
    }
}

#Preview {
    OptionPill(title: "Sex", isSelected: .constant("Sex"), onTap: {})
}

