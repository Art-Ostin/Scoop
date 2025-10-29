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
    @State private var showPrompts = false
    
    let promptIndex: Int
    
    private var key: UserProfile.Field {
        [.prompt1, .prompt2, .prompt3] [promptIndex]
    }
    
    private var keyPath: WritableKeyPath<UserProfile, PromptResponse> {
        [\UserProfile.prompt1, \UserProfile.prompt2, \UserProfile.prompt3] [promptIndex]
    }
    
    private var prompts: [String] {
        let p = Prompts.instance
        return [p.prompts1, p.prompts2, p.prompts3] [promptIndex]
    }

    
    var body: some View {
        VStack(spacing: 12) {
            selector
            textEditor
            
            if case .onboarding(_, let advance) = mode {
                NextButton(isEnabled: prompt.response.count > 3) {
                    isFocused = false
                    advance()
                    vm.setPrompt(key, keyPath, to: prompt)
                }
                .padding(.top, 48)
            }
        }
        .padding(.top, 84)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: prompt) { vm.setPrompt(key, keyPath, to: prompt)}
        .fullScreenCover(isPresented: $showPrompts) {
            SelectPrompt(prompts: prompts, userPrompt: $prompt)
        }
        .onAppear {
            isFocused = true
            if let usersPrompt = vm.draftUser?[keyPath: keyPath] {
                prompt = usersPrompt
            } else {
                prompt = PromptResponse(prompt: prompts.randomElement() ?? "", response: "")
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
                .font(.body(17))
                .lineSpacing(8)
            Spacer()
            Image("EditButtonBlack")
                .font(.body(16, .bold))
                .offset(x: -4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            showPrompts.toggle()
        }
    }
    
    private var textEditor: some View {
        TextEditor(text: $prompt.response)
            .padding()
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .lineSpacing(8)
            .font(.body(17, .medium))
            .stroke(20, lineWidth: 0.5, color: Color.grayPlaceholder)
            .focused($isFocused)
    }
}
