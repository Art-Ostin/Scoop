//
//  OptionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct OptionCell: View {
    
    let title: String
    @Binding var counter: Int
    var width: CGFloat = 148
    @State var isSelected: Bool = false

    var onTap: (() -> Void)
    
    
    
    var body: some View {
        Text(title)
            .frame(width: width, height: 44)
            .background (isSelected ? Color.accentColor : Color.grayBackground, in: RoundedRectangle(cornerRadius: 20))
            .font(.body(16, .bold))
            .foregroundStyle(isSelected ? Color.white : Color.black)
            .onTapGesture {
                isSelected = true
                counter += 1
            }
    }
}

#Preview {
    OptionCell(title: "Sex", counter: .constant(0), onTap: {})
}
