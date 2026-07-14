//
//  WideActionButton.swift
//  Scoop Test
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI

struct WideActionButton: View {
    
    let text: String
    var isComplete: Bool = false
    
    let wideColor = Color(red: 0.55, green: 0, blue: 0.25)

    let action: () -> ()
    
    
    
    var body: some View {
        
        if isComplete {
            ScoopButton
            
            
        
        

            return Group {
                if draft.isComplete {
                    ScoopButton(style: .tinted( ui.isPopupOpenDelayed() ? .fillGray : color, shadow: nil), shape: Capsule(), action: onSendInvite) {
                        label
                    }
                } else {
                    label
                        .background(Color.fillGray, in: Capsule())
                }
            }
            .animation(.smooth, value: ui.isPopupOpenDelayed())
            .opacity(ui.isPopupOpenDelayed() ? 0.4 : 1)
            .allowsHitTesting(draft.isComplete)
            .padding(.top, Spacing.xxs)
        }
        
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
    
    private var buttonLabel: some View {
        Text(text)
            .font(.body(18, .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
    }
}
