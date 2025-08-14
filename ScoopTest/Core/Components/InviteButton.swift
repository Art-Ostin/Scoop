//
//  InviteButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct InviteButton: View {
    
    @Binding var vm: ProfileViewModel
    
    var isInvite: Bool {
        vm.event != nil
    }
    
    var body: some View {
        Button {
            vm.showInvite.toggle()
        } label: {
            Group {
                if isInvite { Image (systemName: "heart").resizable().frame(width: 25, height: 25).font(.body(17, .bold))} else {Image("LetterIconProfile")}
            }
            .foregroundStyle(.white)
            .frame(width: 53, height: 53)
            .background(
                Circle()
                    .fill(isInvite ? Color.appGreen : Color.accent)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 5)
            )
        }
    }
}
