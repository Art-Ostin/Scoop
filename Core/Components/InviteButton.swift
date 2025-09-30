//
//  InviteButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI



struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.3 : 1)
            .brightness(configuration.isPressed ? 1.1 : 1)
    }
}

extension View {
    
    func customButtonStyle() -> some View {
        buttonStyle(PressableButtonStyle())
    }
}

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
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
            )
            .customButtonStyle()
        }
    }
}

