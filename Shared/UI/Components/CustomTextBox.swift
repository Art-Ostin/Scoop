//
//  CustomTextField.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct CustomTextBox: View {
    
    let placeholder: String
    @Binding var textBinding: String
    let characterLimit: Int
    
    let warningThreshold = 25
    
    var body: some View {
        FocusedTextView(text: $textBinding, font: .body(18), lineSpacing: 5, placeholderLineSpacing: 5, maxLength: characterLimit, placeholder: placeholder)
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .stroke(12, lineWidth: 1, color: .grayPlaceholder)
            .overlay(alignment: .bottomTrailing) {
                let remaining = max(0, characterLimit - (textBinding).count)
                if remaining <= 25 {
                    Text("\(remaining)")
                        .font(.body(14))
                        .foregroundStyle(Color.warningYellow)
                        .padding(.trailing, 12)
                        .padding(.bottom, 10)
                }
            }
    }
}
//
//#Preview {
//    CustomTextBox()
//}
