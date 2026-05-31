//
//  ButtonTestView.swift
//  Scoop Test
//
//  Created by Art Ostin on 31/05/2026.

import SwiftUI

struct ButtonTestView: View {
    var body: some View {
        
        VStack(spacing: 72) {
            shrinkButton
            
            growButton
            
        }
    }
}

extension ButtonTestView {
    
    private var growButton: some View {
        
        Button {
        } label: {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 40, height: 40)
                .glassIfAvailable(Circle(), isClear: false, tint: .accent)
//                .surfaceShadow(.floating, strength: 3)
        }
        .glassButtonStyleIfAvailable()
    }
    
    
    
    private var shrinkButton: some View {
        
        Button {
        } label: {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 40, height: 40)
                .glassIfAvailable(Circle(), isClear: false, tint: .accent)
                .surfaceShadow(.floating, strength: 3)
        }
        .buttonStyle(.secondary)
    }
}




#Preview {
    ButtonTestView()
}
