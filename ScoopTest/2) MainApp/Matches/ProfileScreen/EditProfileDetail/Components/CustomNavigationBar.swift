//
//  CustomNavigationBar.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/07/2025.
//

import SwiftUI

struct CustomNavigation: ViewModifier {
    
    @Environment(\.dismiss) private var dismiss
    
    let isOnboarding: Bool
    let onTap: () -> ()
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden()
            .toolbar {
                if isOnboarding {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                                dismiss()
                        } label: {
                            Text("SAVE")
                                .font(.body(12))
                                .foregroundStyle(Color.grayText)
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        CustomBackButton()
                    }
                }
            }
    }
}

extension View {
    func customNavigation(isOnboarding: Bool, onTap: @escaping () -> Void = {}) -> some View {
        modifier(CustomNavigation(isOnboarding: isOnboarding, onTap: onTap))
    }
}
