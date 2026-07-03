//
//  HideButton.swift
//  Scoop
//
//  Created by Art Ostin on 23/06/2026.
//

import SwiftUI

struct HidePopup: View {
    
    let onHide: () -> Void

    var body: some View {
        ScoopButton(style: .clearGlass, shape: .capsule, action: {onHide()}) {
            Text("Hide")
                .font(.title(14, .bold))
                .kerning(1.5)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
        }
    }
}

/*
 Button(action: onHide) {
     Text("Hide")
         .font(.title(14, .bold))
         .kerning(1.5)
         .foregroundStyle(Color.textPrimary)
         .padding(36)
         .contentShape(Rectangle())
 }
 .padding(-36)

 */
