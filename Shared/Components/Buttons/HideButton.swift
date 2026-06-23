//
//  HideButton.swift
//  Scoop Test
//
//  Created by Art Ostin on 23/06/2026.
//

import SwiftUI

struct HidePopup: View {
    
    let onHide: () -> Void

    var body: some View {
        Button(action: onHide) {
            Text("Hide")
                .font(.title(14, .bold))
                .kerning(1.5)
                .foregroundStyle(Color.black)
                .padding(36)
                .contentShape(Rectangle())
        }
        .padding(-36)
    }
}
