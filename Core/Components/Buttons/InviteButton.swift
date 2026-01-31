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
            .scaleEffect(withAnimation(.easeInOut) { configuration.isPressed ? 0.9 : 1 })
            .brightness(configuration.isPressed ? 0.1 : 0)
    }
}

extension View {
    func customButtonStyle() -> some View {
        buttonStyle(PressableButtonStyle())
    }
}

 struct InviteButton: View {
 @Bindable var vm: ProfileViewModel
 @Binding var showInvite: Bool
 var body: some View {
   Button {
       showInvite.toggle()
   } label: {
       Group {
           if vm.viewProfileType == .accept {
               Image (systemName: "heart")
                   .resizable()
                   .frame(width: 25, height: 25)
                   .font(.system(size: 25, weight: .heavy))
           } else {
               Image("LetterIconProfile")
                   .resizable()
                   .scaledToFit()
                   .frame(width: 24, height: 24)
           }
       }
       .foregroundStyle(.white)
       .frame(width: 40, height: 40)
       .background(
           Circle()
               .fill(vm.viewProfileType == .accept ? Color.appGreen : Color.accent)
               .shadow(color: .black.opacity(0.1), radius: 1.32, x: 0, y: 4.4)
       )
   }
   .customButtonStyle()
 }
 }


/*

 struct InviteButton: View {
     @Bindable var vm: ProfileViewModel
     @Binding var showInvite: Bool
     
     var body: some View {
         let isAccept = vm.viewProfileType == .accept
         let image: Image = isAccept ? Image (systemName: "heart"): Image("LetterIconProfile")
         
         image
             .frame(width: 24, height: 24)
             .background(
                 Circle()
                     .fill(vm.viewProfileType == .accept ? Color.appGreen : Color.accent)
                     .frame(width: 40, height: 40)
             )
             .stroke(100, lineWidth: 1, color: .accent)
             .contentShape(Circle())
             .shadow(color: .black.opacity(0.05), radius: 1.5, x: 0, y: 3)
             .onTapGesture {
                 showInvite.toggle()
             }
     }
 }
  
 */
