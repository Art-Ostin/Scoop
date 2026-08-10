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

    private let textShift: CGFloat = 7.5
    private let arrowShift: CGFloat = 20

    var body: some View {

        ScoopButton(style: .tinted(.textAccent, shadow: .button, glass: true), shape: .capsule, press: .grow) {
            withAnimation(.transition) { isEdit.toggle() }
        } label: {
            ZStack {
                ZStack { //Stable slot: the words swap inside it, the slot itself slides
                    Text(isEdit ? "View" : "Edit")
                        .font(.body(14, .bold))
                        .transition(.blurReplace)
                        .id(isEdit)
                }
                .offset(x: isEdit ? textShift : -textShift)

                //One chevron for both states: turned 180° it *is* chevron.left.
                Image(systemName: "chevron.right")
                    .font(.body(12, .bold))
                    .rotationEffect(.degrees(isEdit ? 180 : 0))
                    .offset(x: isEdit ? -arrowShift : arrowShift, y: -1) //Geometry: -1 optical nudge onto the text
                    .animation(.move, value: isEdit)
            }
            .frame(width: 75, height: 35)
        }
        .padding(.bottom, 48)
    }
}

/*
 
 struct EditProfileButtonOld: View {
     
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

 */
