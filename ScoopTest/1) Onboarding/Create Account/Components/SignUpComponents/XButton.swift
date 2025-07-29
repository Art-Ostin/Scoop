//
//  XButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct XButton: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {

        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .fontWeight(.bold)
                .foregroundStyle(.black)
                .font(.system(size: 14))
        }
    }
}
#Preview(traits: .sizeThatFitsLayout) {
    XButton()
}
