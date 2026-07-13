//
//  ViewProfileButton.swift
//  Scoop
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct EditProfileButton: View {
    
    @Binding var isEdit: Bool
    
    let pathIsEmpty: Bool
    
    var body: some View {
        Group {
            if isEdit {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.body(12, .bold))
                        .offset(y: -1)
                    Text("View")
                        .font(.body(14, .bold))
                }
            } else {
                HStack {
                    Text("Edit")
                        .font(.body(14, .bold))
                    Image(systemName: "chevron.right")
                        .font(.body(12, .bold))
                        .offset(y: -1)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.white)
                .shadow(.floating)
                .stroke(CornerRadius.lg, lineWidth: 1, color: .accent)
        )
        .padding(.bottom)
        .onTapGesture {withAnimation (.transition) {isEdit.toggle()}}
        .animation(.toggle, value: isEdit)
        .opacity(pathIsEmpty ? 1 : 0)
        .allowsHitTesting(pathIsEmpty ? true : false)
    }
}


//#Preview {
//    EditProfileButton(mode: .constant(EditUserView()))
//}
