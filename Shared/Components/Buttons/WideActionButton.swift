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
    let onTap: () -> ()
    
    var body: some View {
        
        if isActive {
            ScoopButton(style: .tinted(.textAccent), shape: .capsule, action: onTap) {
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

/*
 @ViewBuilder
 private var sendButton: some View {
     let interactive = confirmInviteScreen || draft.isComplete
     let tint: Color = popupDim || !interactive ? .fillGray : .textAccent
     
     //Don't want glass button for grayed out part of button as gives it default shadow
     let label = Text(confirmInviteScreen ? "Confirm & Send" : "Invite \(name)")
         .font(.body(18, .bold))
         .foregroundStyle(.white)
         .frame(maxWidth: .infinity)
         .frame(height: 48)
         .contentTransition(.opacity) //label cro
     
     
     if draft.isComplete {
         ScoopButton(style: .tinted(tint, shadow: nil), shape: Capsule(), action: buttonTapped) {
             label
         }
         .simultaneousGesture(sendButtonTouch)
         .onDisappear { updateSendButtonTouch(false) }
         .opacity(popupDim ? 0.4 : 1)
         .allowsHitTesting(interactive)
         .padding(.top, confirmInviteScreen ? Spacing.md : Spacing.xxs)
         .padding(.horizontal, Spacing.margin)
         .animation(.smooth(duration: 0.25), value: popupDim)
     } else {
         label
             .background(Color.fillGray, in: Capsule())
             .padding(.horizontal, Spacing.lg)
     }
 }

 */
