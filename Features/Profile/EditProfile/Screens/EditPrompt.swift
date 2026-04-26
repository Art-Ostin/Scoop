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

struct OnboardingPrompt: View {
    @Bindable var vm: OnboardingViewModel
    let promptIndex: Int
    private var key: UserProfile.Field {
        [.prompt1, .prompt2, .prompt3] [promptIndex]
    }
    private var keyPath: WritableKeyPath<DraftProfile, PromptResponse> {
        [\DraftProfile.prompt1, \DraftProfile.prompt2] [promptIndex]
    }
    @State var prompt = PromptResponse(prompt: "", response: "")
    
    var body: some View {
        PromptGeneric(prompt: $prompt, promptIndex: promptIndex)
            .nextButton(isEnabled: prompt.response.count > 3, padding: 24) {
                vm.saveAndNextStep(kp: keyPath, to: prompt)
            }
            .onAppear {
                if let draft = vm.draftProfile {
                    if promptIndex == 0 {
                        if !draft.prompt1.response.isEmpty {
                            prompt.prompt = draft.prompt1.prompt
                            prompt.response = draft.prompt1.response
                        }
                    } else if promptIndex == 1 {
                        if !draft.prompt2.response.isEmpty {
                            prompt.prompt = draft.prompt2.prompt
                            prompt.prompt = draft.prompt2.response
                        }
                    }
                }
            }
    }
}

struct EditPrompt: View {
    @Bindable var vm: EditProfileViewModel
    @Environment(\.dismiss) private var dismiss
    let promptIndex: Int
    @State var showEmptyAlert: Bool = false
    private var key: UserProfile.Field {
        [.prompt1, .prompt2, .prompt3] [promptIndex]
    }
    private var keyPath: WritableKeyPath<UserProfile, PromptResponse> {
        [\UserProfile.prompt1, \UserProfile.prompt2, \UserProfile.prompt3] [promptIndex]
    }
    var prompt: Binding<PromptResponse> {
        Binding {vm.draft[keyPath: keyPath]} set: {
            vm.setPrompt(key, keyPath, to: $0)
        }
    }
    
    var body: some View {
        
        let check = (promptIndex == 0 || promptIndex == 1) && prompt.wrappedValue.response.isEmpty
        
        PromptGeneric(prompt: prompt, promptIndex: promptIndex)
            .closeAndCheckNavButton(check: check, triggerAlert: $showEmptyAlert)
            .customAlert(isPresented: $showEmptyAlert, message: "Can't leave this prompt empty", showTwoButtons: false, onOK: { showEmptyAlert.toggle()})
    }
}

struct PromptGeneric: View {
    @FocusState var isFocused: Bool
    @Binding var prompt: PromptResponse
    @State var showPrompts = false
    let promptIndex: Int
    let maxChars = 110

    private var prompts: [String] {
        let p = Prompts.instance
        return [p.prompts1, p.prompts2, p.prompts3] [promptIndex]
    }
    
    let promptTitle: [String] = ["Prompt 1", "Prompt 2", "Prompt 3"]

    var body: some View {
        VStack(spacing: 60) {
            SignUpTitle(text: promptTitle[promptIndex])
            VStack(spacing: 36) {
                selector
                textEditor
            }
        }
        .onAppear {
            isFocused = true
            if prompt.prompt.isEmpty {prompt.prompt = prompts.randomElement() ?? "My Ideal Date"}
        }
        .padding(.top, 24)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fullScreenCover(isPresented: $showPrompts) {SelectPrompt(prompts: prompts, userPrompt: $prompt, promptIndex: promptIndex)}
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
    }
}

extension PromptGeneric {
    private var selector: some View {
        HStack (spacing: 24) {
            Text(prompt.prompt)
                .font(.body(16))
                .lineSpacing(8)

            Image(systemName: "chevron.down")
                .font(.body(16, .bold))
                .offset(x: -4)
                .foregroundStyle(.accent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {showPrompts.toggle()}
    }
    
//    @ViewBuilder
    private var textEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $prompt.response)
                .padding()
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .lineSpacing(8)
                .font(.body(17, .medium))
                .focused($isFocused)
                .lineLimit(3)
                .onChange(of: prompt.response) { _, newValue in
                    if newValue.count > maxChars {
                        prompt.response = String(newValue.prefix(maxChars))
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    let remaining = max(0, maxChars - (prompt.response).count)
                    if remaining <= 25 {
                        Text("\(remaining)")
                            .font(.body(14))
                            .foregroundStyle(Color.warningYellow)
                            .padding(.trailing, 12)
                            .padding(.bottom, 10)
                    }
                }
            
            
            if prompt.response.isEmpty {
                Text("Type your response here")
                    .font(.body(17, .medium))
                    .foregroundStyle(Color.grayPlaceholder)
                // Match the TextEditor’s visual inset
                    .padding(.horizontal, 22)
                    .padding(.vertical, 24)
                    .allowsHitTesting(false)
            }
        }
        .stroke(20, lineWidth: 0.5, color: Color.grayPlaceholder)
    }
}
