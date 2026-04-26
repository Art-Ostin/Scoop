//
//  DismissButton.swift
//  Scoop
//
//  Created by Art Ostin on 03/02/2026.
//

import SwiftUI

struct DismissButton: View {
    let dismiss: () -> ()
    var body: some View {
        Button {
            dismiss()
        } label : {
            Image(systemName: "xmark")
                .font(.body(18, .bold))
                .padding(12)
                .glassIfAvailable(Circle())
                .contentShape(Circle())
                .foregroundStyle(Color.black)
                .padding(.horizontal)
        }
    }
}
