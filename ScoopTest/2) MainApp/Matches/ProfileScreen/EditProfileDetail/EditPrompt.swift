//
//  PromptView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct EditPrompt: View {
    
    @State var selectedText: String = ""
    @FocusState var isFocused: Bool
    
    @State var showDropdownMenu: Bool = false
    
    @State var prompts: [String] = ["In five years time I hope to be:", "My ideal Saturday Night involves", "My ideal Thursday involves", "My Pleasures", "The dream date", "My biggest F**K up", "Since arriving at McGill I’ve learnt"]
    @State var selectedPrompt: String = "In five years time I hope to be:"
    
    var body: some View {
        
        ZStack {
            
            VStack(spacing: 12) {
                selecter
                textEditor
            }
            if showDropdownMenu {
                dropdownMenu
                    .offset(y: -60)
            }
        }
        .onAppear {
            isFocused = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 160)
        .onTapGesture {
            if showDropdownMenu {
                showDropdownMenu = false
            }
        }
    }
}

#Preview {
    EditPrompt()
}


extension EditPrompt {
    
    
    private var selecter: some View {
        
        HStack {
            Text(selectedPrompt)
                .font(.body(17, .bold))
                .lineSpacing(8)
            Spacer()
            Image("EditButtonBlack")
                .font(.body(16, .bold))
                .offset(x: -4)
        }
        .frame(width: 340)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            showDropdownMenu.toggle()
        }
    }
    
    
    private var dropdownMenu: some View {
        DropDownMenu(width: 350) {
                ForEach(prompts, id: \.self) {prompt in
                    Group {
                        Text(prompt)
                            .font(selectedPrompt == prompt ? .body(17, .bold) : .body(17))
                            .foregroundStyle(selectedPrompt == prompt ? Color.accent : .black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture {
                                selectedPrompt = prompt
                                showDropdownMenu = false
                            }
                        if prompt != prompts.last {SoftDivider()}
                    }
                }
        }
    }
    
    private var textEditor: some View {
        
        TextEditor(text: $selectedText)
            .padding()
            .scrollContentBackground(.hidden)
            .frame(width: 350, height: 120)
            .lineSpacing(8)
            .font(.body(17, .bold))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.grayPlaceholder, lineWidth: 0.5)
            )
            .focused($isFocused)
    }
}
