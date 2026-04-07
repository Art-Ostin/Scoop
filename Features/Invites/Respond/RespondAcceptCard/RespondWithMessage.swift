//
//  RespondWithMessage.swift
//  Scoop
//
//  Created by Art Ostin on 06/04/2026.
//

import SwiftUI

struct RespondWithMessage: View {
    let message: String
    let messageResponse: String?

    @Binding var showMessageButton: Bool
    
    var body: some View {
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
            .overlay(alignment: .topLeading) {overlayQuote}
            .overlay(alignment: .bottomTrailing) {overlayQuote}
            .layoutPriority(1)
            .overlay(alignment: .topTrailing) {
                if messageResponse?.isEmpty != false {
                    AddMessageButton(showMessageScreen: $showMessageButton, hasEventMessage: true)
                        .offset(x: 6, y: -8)
                }
            }
    }
}

extension RespondWithMessage {

    private var overlayQuote: some View {
        Text("\"")
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .font(.body(16, .medium))
    }
    
}


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
