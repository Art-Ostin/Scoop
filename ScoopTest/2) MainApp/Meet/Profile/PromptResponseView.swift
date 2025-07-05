//
//  PromptResponseView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct PromptResponseView: View {
    
    
    @State var promptSelection: String

    @State var promptResponse: String
    
    @State var inviteButton: Bool
    
    @Binding var showInvite: Bool
        
    var body: some View {
            
        VStack {
            Text(promptSelection)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, 16)
                .font(.body(14, .italic))
            
            Text(promptResponse)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .font(.title(24))
                .lineSpacing(12)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 171)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.78, green: 0.78, blue: 0.78), lineWidth: 1)
            
        )
        .overlay(
            InviteButton(showInvite: $showInvite)
                .padding(.horizontal, 12)
                .offset(y: 24),
            alignment: .bottomTrailing
        )
        .padding(.horizontal, 24)
    }
}

#Preview {
    PromptResponseView(promptSelection: Prompts.instance["on the date"] ?? "Write whatever", promptResponse: "Bannanas and Apples and all the other things", inviteButton: true, showInvite: .constant(true))
        .environment(AppState())
        .offWhite()
}
