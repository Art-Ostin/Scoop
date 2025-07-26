//
//  BackButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct CustomBackButton: View {
    
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.body(17, .bold))
                .foregroundStyle(.black)
                .padding(.top, 22)
        }
    }
}

