//
//  DeclineButton.swift
//  Scoop
//
//  Created by Art Ostin on 02/11/2025.
//

import SwiftUI

struct DeclineButton: View {
    let image: String = "DeclineIcon"
    let onTap: () -> ()
    var body: some View {
                Image(image)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.background)
                )
                .stroke(100, lineWidth: 1, color: .grayBackground)
                .contentShape(Circle())
                .shadow(color: .black.opacity(0.05), radius: 1.5, x: 0, y: 3)
                .onTapGesture {onTap()}
        }
}


