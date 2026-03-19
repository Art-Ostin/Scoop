//
//  CardFlipAnimationTest.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

/*
 
 import SwiftUI


 struct CardFlipView: View {
     
     @State var isFlipped = false
     
     var body: some View{
         
         ZStack {
             if isFlipped {
                 BackOfCard()
                     .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))

             } else {
                 FrontOfCard()
             }
         }
         .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
         .animation(.easeInOut, value: isFlipped)
         .onTapGesture {
             isFlipped.toggle()
         }
     }
 }




 struct FrontOfCard: View {
         
     
     var body: some View {
         VStack {
             
             ClearRectangle(size: 150)
             
         }
         .background(
             RoundedRectangle(cornerRadius: 22)
                 .fill(Color.background)
                 .shadow(color: .black.opacity(0.25), radius: 1.8, x: 0, y: 3.6)
         )
         .stroke(22, lineWidth: 1, color: Color(red: 0.96, green: 0.96, blue: 0.96))
     }
 }

 #Preview {
     CardFlipView()
 }


 struct BackOfCard: View {
     
     var body: some View {
         VStack {
             
             
             ClearRectangle(size: 150)
             
         }
         .background(
             RoundedRectangle(cornerRadius: 22)
                 .fill(Color.blue)
                 .shadow(color: .black.opacity(0.25), radius: 1.8, x: 0, y: 3.6)
         )
         .stroke(22, lineWidth: 1, color: Color(red: 0.96, green: 0.96, blue: 0.96))
     }
     
     
 }
 */

