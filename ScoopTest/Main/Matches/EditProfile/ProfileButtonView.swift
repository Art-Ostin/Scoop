//
//  ViewProfileButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct EditProfileButton: View {
    
    @Binding var isView: Bool
    
    var body: some View {
        
        Group {
            
            if isView {
                HStack {
                    
                    HStack {
                        Text("Edit")
                            .font(.body(14, .bold))
                        
                        Image(systemName: "chevron.right")
                    }
                }
            } else {
                HStack {
                    HStack {
                        
                        Image(systemName: "chevron.left")

                        Text("View" )
                            .font(.body(14, .bold))
                    }
                }
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
    }
}

//#Preview {
//    EditProfileButton(mode: .constant(EditUserView()))
//}
