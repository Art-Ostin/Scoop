//
//  MinimalistButton.swift
//  Scoop
//
//  Created by Art Ostin on 26/02/2026.
//

import SwiftUI

struct MinimalistButton: View {
    
    let text: String
    let action: () -> ()
    
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(text)
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
