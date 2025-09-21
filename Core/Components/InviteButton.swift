//
//  InviteButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct InviteButton: View {
    @Binding var vm: ProfileViewModel
    var body: some View {
        Button {
            vm.showInvitePopup.toggle()
        } label: {
            Group {
                if vm.viewProfileType == .accept {
                    Image (systemName: "heart")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .font(.system(size: 25, weight: .heavy))
                } else {
                    Image("LetterIconProfile")
                }
            }
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(vm.viewProfileType == .accept ? Color.appGreen : Color.accent)
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 5)
            )
        }
    }
}

