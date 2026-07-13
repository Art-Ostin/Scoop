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
        ScoopButton(
            style: .tinted(.accent),
            shape: RoundedRectangle(cornerRadius: CornerRadius.md)
        ) {
            dismiss()
        } label: {
            Text("OK")
                .font(.body(17, .bold))
                .frame(width: 100, height: 40) //Geometry: fixed OK-button footprint
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, Spacing.lg)
    }
}

#Preview {
    OkDismissButton()
}
