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

    private var prompts: [String] {
        let p = Prompts.instance
        return [p.prompts1, p.prompts2, p.prompts3] [promptIndex]
    }

    var body: some View {
        VStack(spacing: 12) {
            selector
            textEditor
        }
        .onAppear {
            isFocused = true
            if prompt.prompt.isEmpty {prompt.prompt = prompts.randomElement() ?? "My Ideal Date"}
        }
        .padding(.top, 60)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fullScreenCover(isPresented: $showPrompts) {SelectPrompt(prompts: prompts, userPrompt: $prompt)}
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
    }
}

extension PromptGeneric {
    private var selector: some View {
        HStack {
            Text(prompt.prompt)
                .font(.body(17))
                .lineSpacing(8)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.body(16, .bold))
                .offset(x: -4)
                .foregroundStyle(.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {showPrompts.toggle()}
    }
    
    private var textEditor: some View {
        TextEditor(text: $prompt.response, placeholder: "Type Your Response here")
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
