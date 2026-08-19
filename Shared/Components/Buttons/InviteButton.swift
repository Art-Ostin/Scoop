//
//  InviteButton.swift
//  Scoop
//
//  Created by Art Ostin on 30/05/2026.
//

import SwiftUI



struct InviteButton: View {
    let onTap: () -> ()
    
    var shadow: Elevation? = nil
    
    var body: some View {
        ScoopButton(style: .tinted(.accent, shadow: shadow), shape: Circle()) { //.accent.black.mix(with: .accent, by: 0.2)
            onTap()
        } label: {
            Image("LetterIconProfile")
                .font(.body(24, .bold))
                .foregroundStyle(Color.white)
                .scaleEffect(0.8)
                .frame(width: 42, height: 42)
        }
    }
}


/*
 
 struct InviteButton: View {

     static let diameter: CGFloat = 40 //Geometry: circular tap-target diameter

     let isInviting: Bool
     var isInviteCard: Bool = false

     let action: () -> Void

     var body: some View {
         ScoopButton(style: .tinted(isInviting ? Color.accent : Color.successGreen, shadow: isInviteCard ? nil : .floating), shape: Circle(), action: action) {
             Image("LetterIconProfile")
                 .resizable()
                 .scaledToFit()
                 .frame(width: 24, height: 24)
                 .frame(width: Self.diameter, height: Self.diameter)
         }
     }
 }
 */

