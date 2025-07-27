//
//  ViewProfileButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct ViewProfileButton: View {
    var body: some View {
        HStack {
            Image("Image1")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .clipShape(Circle())
            
            Text("View Profile")
                .font(.body(14, .bold))
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.grayBackground, lineWidth: 1)
                )
        )
        .frame(maxHeight: .infinity, alignment: .bottom)
        .offset(y: 12)
    }
}

#Preview {
    ViewProfileButton()
}
