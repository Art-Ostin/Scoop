//
//  OkDismissButton.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct OkDismissButton: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button {
            dismiss()
        } label : {
            Text("OK")
                .frame(width: 100, height: 40)
                .foregroundStyle(Color.white)
                .font(Font.body(17, .bold))
                .background (
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color.accent)
                        .shadow(color: .black.opacity(0.12), radius: 2, y: 4)
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
        }
    }
}

#Preview {
    OkDismissButton()
}
