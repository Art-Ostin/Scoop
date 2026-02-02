//
//  SignOutButton.swift
//  Scoop
//
//  Created by Art Ostin on 03/12/2025.
//

import SwiftUI

struct SignOutButton: View {
    let onTap: () -> Void
    var body: some View {
        Button {
            onTap()
        } label : {
            Text("Sign out")
                .font(.body(14, .bold))
                .padding(8)
                .foregroundStyle(.black)
                .background (
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white )
                        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
                )
                .overlay (
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.black, lineWidth: 1)
                )
                .padding(.horizontal, 16)
        }
    }
}
