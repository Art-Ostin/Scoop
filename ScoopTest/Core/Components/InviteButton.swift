//
//  InviteButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct InviteButton: View {
    
    @Bindable var vm: ProfileViewModel
    
    
    var body: some View {
        Button {
            vm.invitePopup.toggle()
        } label: {
            Image("LetterIconProfile")
                .foregroundStyle(.white)
                .frame(width: 53, height: 53)
            
                .background(
                    Circle()
                        .fill(Color.accent.opacity(0.95))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 5)
                )
        }
    }
}
