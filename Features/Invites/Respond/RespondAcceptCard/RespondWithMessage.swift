//
//  RespondWithMessage.swift
//  Scoop
//
//  Created by Art Ostin on 06/04/2026.
//

/*
 
 import SwiftUI


 struct NewRespondWithMessage: View {
     
     @Binding var showMessageButton: Bool

     let message: String
     
     var body: some View {
         Button {
             showMessageButton = true
         } label: {
             Text(message)
                 .font(.body(14, .medium))
                 .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                 .lineSpacing(3)
                 .padding(.horizontal, 6)
                 .padding(.leading, 2)
                 .padding(.vertical, 4)
                 .background (
                     RoundedRectangle(cornerRadius: 12)
                         .fill(Color.background)
                         .overlay {
                             RoundedRectangle(cornerRadius: 12)
                                 .stroke(Color.grayPlaceholder.opacity(0.1),
                                     style: StrokeStyle(lineWidth: 1, lineJoin: .round)
                                 )
                         }
                 )
                 .frame(maxWidth: .infinity, alignment: .trailing)
                 .multilineTextAlignment(.leading)
         }
     }
 }





 struct RespondWithMessage: View {
     let message: String
     let messageResponse: String?

     @Binding var showMessageButton: Bool
     
     var body: some View {
         
         Button {
             showMessageButton = true
         } label: {
             Text(message)
                 .font(.body(14, .medium))
                 .lineSpacing(5)
                 .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                 .frame(maxWidth: .infinity, alignment: .center)
                 .multilineTextAlignment(.leading)
                 .padding(.vertical, 9)
                 .padding(.horizontal, 20)
                 .padding(.trailing, 8)
                 .background(
                     RoundedRectangle(cornerRadius: 12)
                         .foregroundStyle(Color(red: 0.93, green: 0.93, blue: 0.93))
                 )
                 .overlay(alignment: .topLeading) {overlayQuoteTop}
                 .overlay(alignment: .bottomTrailing) {overlayQuoteBottom}
                 .layoutPriority(1)
                 .overlay(alignment: .topTrailing) {
                     if messageResponse?.isEmpty != false {
                         Image("GreenMessageIcon")
                             .padding(6)
                             .padding(.horizontal, 1.8)
                     }
                 }
         }
     }
 }

 extension RespondWithMessage {

     private var overlayQuoteTop: some View {
         Text("“")
             .font(.system(size: 18, weight: .bold, design: .serif))
             .padding(.leading, 7)
             .offset(y: 3)
     }
     
     private var overlayQuoteBottom: some View {
         Text("”")
             .font(.system(size: 18, weight: .bold, design: .serif))
             .padding(.trailing, 7)
             .offset(y: 1)
     }
 }

 
 */


/*
 
 
 private var addMessageButton: some View {
     Button {
         showMessageButton = true
     } label : {
         Image("AddMessageIcon")
             .padding(12)
             .contentShape(Rectangle())
             .padding(-12)
             .padding(6)
             .background(
                 Circle()
                     .foregroundStyle(Color.white).opacity(0.7)
             )
             .stroke(100, lineWidth: 0.5, color: .grayPlaceholder.opacity(0.5))
     }
 }

 
 
 Spacer(minLength: 8)
 
 private func eventResponse(_ response: String) -> some View {
     Text(message)
         .font(.body(14, .medium))
         .lineSpacing(2)
         .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
         .frame(maxWidth: .infinity, alignment: .center)
         .multilineTextAlignment(.leading)
         .padding(.vertical, 10)
         .padding(.horizontal, 24)
         .background(
             RoundedRectangle(cornerRadius: 12)
                 .foregroundStyle(Color(red: 0.93, green: 0.93, blue: 0.93))
         )
 }

 MessageAddButton(showMessageScreen: $showMessageButton)
     .fixedSize()

 */
