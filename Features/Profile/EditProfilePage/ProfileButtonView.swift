//
//  ViewProfileButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct EditProfileButton: View {
    
    @Binding var isEdit: Bool
    
    var body: some View {
        Group {
            if isEdit {
                HStack {
                    Text("View")
                        .font(.body(14, .bold))
                    Image(systemName: "chevron.right")
                        .font(.body(12, .bold))
                        .offset(y: -1)
                }
            } else {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.body(12, .bold))
                        .offset(y: -1)
                    Text("Edit" )
                        .font(.body(14, .bold))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 10)
                .stroke(20, lineWidth: 1, color: .accent)
        )
        .padding(.bottom)
        .onTapGesture {withAnimation (.easeInOut(duration: 0.3)) {isEdit.toggle()}}
        .animation(.spring(), value: isEdit)
    }
}


//#Preview {
//    EditProfileButton(mode: .constant(EditUserView()))
//}
