//
//  PromptView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct PromptResponse: Codable, Equatable  {
    var prompt: String
    var response: String
}


struct EditPrompt: View {
    @Environment(\.flowMode) private var mode
    @Bindable var vm: EditProfileViewModel
        
    @FocusState var isFocused: Bool
    @State var prompt = PromptResponse(prompt: "", response: "")
    @State private var showDropdownMenu = false
    
    
    let prompts: [String]
    let promptIndex: Int
    
    private var key: UserProfile.CodingKeys {
        [.prompt1, .prompt2, .prompt3] [promptIndex]
    }
    private var keyPath: WritableKeyPath<UserProfile, PromptResponse?> {
        [\UserProfile.prompt1, \UserProfile.prompt2, \UserProfile.prompt3] [promptIndex]
    }

    var body: some View {
        
        ZStack {
            VStack(spacing: 12) {
                selector
                textEditor
                
                if case .onboarding(_, let advance) = mode {
                    NextButton(isEnabled: prompt.response.count > 3) {
                        isFocused = false
                        advance()
                    }
                }
            }
            if showDropdownMenu {
                dropdownMenu
                    .offset(y: -48)
            }
        }
        .onChange(of: prompt) { vm.setPrompt(key, keyPath, to: prompt)}
        
        .onAppear {
            isFocused = true
            if let prompt = vm.draftUser[keyPath: keyPath] {
                self.prompt = prompt
            } else {
                self.prompt = PromptResponse(prompt: prompts.randomElement() ?? "", response: "")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .flowNavigation()
    }
}

extension EditPrompt {
    
    private var selector: some View {
        
        HStack {
            Text(prompt.prompt)
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
            ForEach(prompts, id: \.self) {option in
                Group {
                    Text(option)
                        .font(prompt.prompt == option ? .body(17, .bold) : .body(17))
                        .foregroundStyle(prompt.prompt == option ? Color.accent : .black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            prompt.prompt = option
                            showDropdownMenu = false
                        }
                    if option != prompts.last { SoftDivider() }
                }
            }
        }
    }
    
    private var textEditor: some View {
        TextEditor(text: $prompt.response)
            .padding()
            .scrollContentBackground(.hidden)
            .frame(width: 350, height: 120)
            .lineSpacing(8)
            .font(.body(17, .medium))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.grayPlaceholder, lineWidth: 0.5)
            )
            .focused($isFocused)
    }
}
