//
//  DeclineButton.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.
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
                        .fill(Color.appCanvas)
                )
                .circleStroke(lineWidth: 1, color: Color.border)
                .contentShape(Circle())
                .shadow(color: .black.opacity(0.05), radius: 1.5, x: 0, y: 3)
                .onTapGesture {onTap()}
                .scaleEffect(1.1)
                .padding(.horizontal, 24)
                .padding(.bottom, 6)
        }
}
