//
//  ViewProfileButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct EditProfileButton: View {
    var body: some View {
        HStack {
            Image("Image1")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .clipShape(Circle())
            
            HStack {
                
                Text("Edit")
                    .font(.body(14, .bold))
                
                NavButton(.right, 14)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.accentColor, lineWidth: 1)
                )
        )
        .frame(maxHeight: .infinity, alignment: .bottom)
        .offset(y: 12)
    }
}

#Preview {
    EditProfileButton()
}
