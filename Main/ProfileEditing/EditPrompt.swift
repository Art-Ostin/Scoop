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
        PromptGeneric(prompt: $prompt, promptIndex: promptIndex) {
            vm.saveAndNextStep(kp: keyPath, to: prompt)
        }
    }
}

struct EditPrompt: View {
    @Bindable var vm: EditProfileViewModel
    let promptIndex: Int
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
        PromptGeneric(prompt: prompt, promptIndex: promptIndex) {}
    }
}

struct PromptGeneric: View {
    @Environment(\.flowMode) private var mode
    @FocusState var isFocused: Bool
    @Binding var prompt: PromptResponse
    @State var showPrompts = false
    let promptIndex: Int
    let onTap: () -> ()

    private var prompts: [String] {
        let p = Prompts.instance
        return [p.prompts1, p.prompts2, p.prompts3] [promptIndex]
    }

    var body: some View {
        VStack(spacing: 12) {
            selector
            textEditor
            if case .onboarding = mode {
                NextButton(isEnabled: prompt.response.count > 3) { isFocused = false ; onTap()}
                    .padding(.top, 48)
            }
        }
        .padding(.top, 84)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fullScreenCover(isPresented: $showPrompts) {SelectPrompt(prompts: prompts, userPrompt: $prompt)}
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .flowNavigation()
    }
}

extension PromptGeneric {
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
        .onTapGesture {showPrompts.toggle()}
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
