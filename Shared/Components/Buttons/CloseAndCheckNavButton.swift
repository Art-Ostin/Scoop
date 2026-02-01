//
//  CloseAndCheckNavButton.swift
//  Scoop
//
//  Created by Art Ostin on 19/01/2026.
//

import SwiftUI

struct CloseAndCheckNavButton: ViewModifier {
    @Environment(\.dismiss)var dismiss
    let check: Bool
    @Binding var triggerAlert: Bool

    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if check {
                            triggerAlert = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 30, height: 50) //Frame Solves a bug for quick dismissing
                            .contentShape(Rectangle())
                    }
                }
            }
   
    }
}

extension View {
    func closeAndCheckNavButton(check: Bool, triggerAlert: Binding<Bool>) -> some View {
        modifier(CloseAndCheckNavButton(check: check, triggerAlert: triggerAlert))
    }
}
