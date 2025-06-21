//
//  PromptView1.swift
//  ScoopTest
//
//  Created by Art Ostin on 21/06/2025.
//

import SwiftUI

struct PromptView1: View {
    
    @State private var promptResponse: String = ""
    
    @FocusState private var isFocused: Bool
    
    @State private var Prompts : [String] = [ "You’ll just have to me me to find out about", "Want to be shocked? Ask me about...", "I will tell you the best place at McGill to...", "My ideal date involves...", "On the date i’ll steer the convo towards..."]
        
        
    @State private var selectedPrompt: [String] = ["You’ll just have to me me to find out about"]
        

    var body: some View {
        
        ZStack {
            
            VStack(alignment: .leading, spacing: 24) {
                
                VStack (alignment: .leading, spacing: 65){
                    SignUpTitle(text: "Prompt 1", count: 3)
                    
                    ZStack{
                        Text("You'll just have to me me to find out about")
                            .frame(width: 288, alignment: .topLeading)
                            .lineSpacing(6)
                            .font(.body())
                            .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        Image(systemName: "chevron.down")
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()
                
                TextEditor(text: $promptResponse)
                    .padding(12)
                    .font(.body(.regular))
                    .focused($isFocused)
                    .background(Color.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1.5)
                            .fill(Color.background)
                    )
                    .frame(height: 108)
            }
        }
        .onAppear {
            isFocused = true
        }
        .padding(32)
    }
}

#Preview {
    PromptView1()
        .offWhite()
}
