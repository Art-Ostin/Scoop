//
//  InviteAcceptPopup.swift
//  ScoopTest
//
//  Created by Art Ostin on 14/08/2025.
//

import SwiftUI

struct InviteAcceptPopup: View {
    
    var body: some View {
        
        GeometryReader { geo in

            VStack(spacing: 24) {
                HStack {
                Text("Arthur's Invite")
                }
                Text("15th April 1945")
                
                Text("message hello world")
                
                ActionButton(text: "Accept", isInvite: true) {
                }
            }
            
            .padding([.bottom, .horizontal], 32)
            .padding(.top, 24)
            .cornerRadius(30)
            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .inset(by: 0.5)
                    .stroke(Color.grayBackground, lineWidth: 0.5)
            )
            frame(width: (geo.size.width - 64))
        }
        
    }
}

#Preview {
    InviteAcceptPopup()
}
