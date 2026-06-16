//
//  SelectTimeAndPlaceCard.swift
//  Scoop
//
//  Created by Art Ostin on 04/05/2026.
//

/*
 
 import SwiftUI

 struct OldTimeAndPlace: ViewModifier {

     let messageCount: Int
     let placeAdded: Bool
     var morphMode: Bool = false
     var messageLarge: Bool {messageCount > 35}

     func body(content: Content) -> some View {
         content
             .frame(alignment: .top)
             .padding(.horizontal, (messageLarge || placeAdded) ? 28 : 32)
             .padding(.vertical, 24)
             .frame(maxWidth: .infinity)
             .background (cardBackground)
             .padding(.horizontal, morphMode ? 0 : horizontalPadding())
     }
 }

 extension View {
     
     func timeAndPlaceCard(
         messageCount: Int,
         placeAdded: Bool,
         morphMode: Bool = false
     ) -> some View {
         modifier(
             TimeAndPlaceCard(
                 messageCount: messageCount,
                 placeAdded: placeAdded,
                 morphMode: morphMode
             )
         )
     }
 }



 extension TimeAndPlaceCard {
     
     @ViewBuilder private var cardBackground: some View {
         if !morphMode {
             ZStack { //Background done like this to fix bugs when popping up
                 RoundedRectangle(cornerRadius: 30)
                     .fill(Color.appCanvas)
                     .shadow(color: .accent.opacity(0.15), radius: 4, y: 2)
                     .shadow(color: .white.opacity(0.2), radius: 7, x: 0, y: 5)
                 RoundedRectangle(cornerRadius: 30)
                     .inset(by: 0.5)
                     .stroke(Color.grayBackground, lineWidth: 0.5)
             }
         }
     }
     
     private func horizontalPadding() -> CGFloat {
         let messageVLarge = messageCount > 80
         
         var originalHPadding: CGFloat = 30
         
         if messageLarge {
             originalHPadding -= 2
         }
         if messageVLarge {
             originalHPadding -= 2
         }
         if placeAdded {
             originalHPadding -= 2
         }
         
         return originalHPadding
     }
 }


 */
