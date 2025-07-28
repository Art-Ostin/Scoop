//
//  PromptView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI


struct EditPrompt: View {
    
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.flowMode) private var mode
    
    @FocusState var isFocused: Bool
    @State var selectedText: String = ""
    @State var selectedPrompt: String = ""
    @State var showDropdownMenu: Bool = false
    
    var prompts: [String]
    var promptIndex: Int

    var body: some View {
                
        ZStack {
            VStack(spacing: 12) {
                selecter
                textEditor
                if case .onboarding(_, let advance) = mode { NextButton(isEnabled: true) { advance() }}
            }
            if showDropdownMenu {
                dropdownMenu
                    .offset(y: -48)
            }
        }
        .onChange(of: selectedText) { updatePrompt() }
        .onChange(of: selectedPrompt) { updatePrompt() }
            
        .onAppear {
            isFocused = true
            if let user = dependencies.userStore.user {
                let promptData: PromptResponse?
                switch promptIndex {
                case 1: promptData = user.prompt1
                case 2: promptData = user.prompt2
                case 3: promptData = user.prompt3
                default: promptData = nil
                }
                selectedPrompt = promptData?.prompt ?? prompts.randomElement() ?? ""
                selectedText = promptData?.response ?? ""
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .flowNavigation()
                
    }
}

#Preview {
    EditPrompt(prompts: Prompts.instance.prompts1, promptIndex: 2)
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
            .font(.body(17, .medium))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.grayPlaceholder, lineWidth: 0.5)
            )
            .focused($isFocused)
    }

    private func updatePrompt() {
        
        guard let user = dependencies.userStore.user else { return }
        let prompt = PromptResponse(prompt: selectedPrompt, response: selectedText)
        Task {
            try? await dependencies.profileManager.updatePrompt(
                userId: user.userId,
                promptIndex: promptIndex,
                prompt: prompt
            )
            try? await dependencies.userStore.loadUser()
        }
    }
}
