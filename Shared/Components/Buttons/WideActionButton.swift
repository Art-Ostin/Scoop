//
//  WideActionButton.swift
//  Scoop Test
//
//  Created by Art Ostin on 20/07/2026.
//

import SwiftUI

struct WideActionButton: View {
    
    let text: String
    let isActive: Bool
    var showShadow: Bool = true

    
    let onTap: () -> ()
        
    var body: some View {
        
        if isActive {
            ScoopButton(style: .tinted(.accent, shadow: showShadow ? .button : nil), shape: .capsule, action: onTap) {
                label
            }
        } else {
            label
                .foregroundStyle(Color.white)
                .background(Color.fillGray, in: .capsule)
        }
    }
    
    private var label: some View {
        Text(text)
            .font(.body(18, .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .geometryGroup()
    }
}
