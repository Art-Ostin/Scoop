//
//  PromptView1.swift
//  ScoopTest
//
//  Created by Art Ostin on 21/06/2025.
//

import SwiftUI

struct PromptView1: View {
    
    @State private var promptOptions1: [String] = [ "You’ll just have to meet me to find out about...", "Want to be shocked? Ask me about...", "I will tell you the best place at McGill to...", "My ideal date involves...", "On the date I’ll steer the convo towards..."
    ]
    
    var body: some View {
        
        PromptView(prompts: promptOptions1, title: "Prompt 1", promptSelectionTitle: "Prompt (1)")
    }
    
}

struct PromptView2: View {
    
    @State private var promptOptions2: [String] = [
        "On a Saturday night you’ll find me...",
        "A Tuesday night involves...",
        "Would you be a sausage or a pear? Why?...",
        "My unapologetic pleasures...",
        "Three words that capture who I am..."
    ]
    
    
    var body: some View {
        
        PromptView(prompts: promptOptions2, title: "Prompt 2", promptSelectionTitle: "Prompt (2)")
    }
}







struct PromptView: View {
    
    let prompts: [String]
    
    let title: String
    
    let promptSelectionTitle: String
    
    @State private var promptResponse: String = ""
    
    @FocusState private var isFocused: Bool
        
    @State private var selectedPrompt: String = ""
    
    @State private var showPrompts: Bool = false

    var body: some View {
        
        ZStack {
            
            VStack(alignment: .leading, spacing: 24) {
                
                VStack (alignment: .leading, spacing: 48){
                    SignUpTitle(text: title, count: 3)
                        .padding(.top, 48)
                    
                    HStack(alignment: .bottom){
                        Text(selectedPrompt)
                            .lineSpacing(6)
                            .frame(width: 300, alignment: .leading)
                            .font(.body())
                            .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                    }
                    .onTapGesture {
                        showPrompts.toggle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 38)
                    .sheet(isPresented: $showPrompts) {
                        promptSelectionView
                    }
                    
                    
                }

                Divider()
                
                TextEditor(text: $promptResponse)
                    .padding(12)
                    .focused($isFocused)
                    .font(.body(17, .regular))
                    .lineSpacing(5)
                    .background(Color.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1.5)
                    )
                    .frame(height: 108)
                    .scrollContentBackground(.hidden)
                    .padding(.bottom, 24)
                
                NextButton(isEnabled: promptResponse.count > 8, onInvalidTap: {})
            }
        }
        .onAppear {
            isFocused = true
            
            if selectedPrompt.isEmpty {
                selectedPrompt = prompts.first ?? ""
            }
        }
    }
}

#Preview {
    PromptView1()
        .offWhite()
        .environment(AppState())
}

extension PromptView {
    
    private var promptSelectionView: some View {
        
      VStack {
          VStack (spacing: 12){
              
              Text(promptSelectionTitle)
                  .font(.body(18, .medium))
              
              Divider().ignoresSafeArea(edges: .all)
                  
              }
          .padding(.bottom, 36)
          
          VStack(spacing: 48){
              ForEach(prompts, id: \.self) {index in
                  Text(index)
                      .frame(width: 296, height: 80)
                      .font(.body(18))
                      .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(selectedPrompt == index ? Color.accent : Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1))
                      .multilineTextAlignment(.center)
                      .onTapGesture {
                          selectedPrompt.removeAll()
                          selectedPrompt.append(index)
                          withAnimation(.easeInOut(duration: 3)) {
                              showPrompts.toggle()
                          }
                      }
              }
          }
        }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .padding(.top, 24)
    }
}
