//
//  ButtonTestView.swift
//  Scoop Test
//
//  Created by Art Ostin on 31/05/2026.

import SwiftUI

struct ButtonTestView: View {
    var body: some View {
        
        VStack(spacing: 72) {

            noShadow
            
            highShadow
            
            mediumShadow

            lowShadow
        }
    }
}

extension ButtonTestView {
    
    private var noShadow: some View {
        
        Button {
        } label: {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 40, height: 40)
                .glassIfAvailable(Circle(), isClear: false, tint: .accent)
        }
        .customButtonPressAndShadow()
    }


    private var highShadow: some View {
        
        Button {
        } label: {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 40, height: 40)
                .buttonColourBackground(Circle())
        }
        .customButtonPressAndShadow(.high)
    }
    
    private var mediumShadow: some View {
        Button {
        } label: {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 40, height: 40)
                .glassIfAvailable(Circle(), isClear: false, tint: .accent)
        }
        .customButtonPressAndShadow(.medium)
    }

    private var lowShadow: some View {

        Button {
        } label: {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 40, height: 40)
                .glassIfAvailable(Circle(), isClear: false, tint: .accent)
        }
        .customButtonPressAndShadow(.low)
    }

}




#Preview {
    ButtonTestView()
}
