//
//  ActionButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct ActionButton: View {
    
    @State var text: String
    
    @State var onTap: () -> Void
    
    var body: some View {
        
        Button {
            onTap()
        } label: {
            Text(text)
                .font(.body(18, .bold))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.tint)
                .foregroundStyle(.white)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}
#Preview{
    ActionButton(text: "Login / Sign Up", onTap: {})
}
