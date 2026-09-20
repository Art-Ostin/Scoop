//
//  PromptView.swift
//  Scoop
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct PromptResponse: Codable, Equatable  {
    var prompt: String
    var response: String
}

struct OnboardingPrompt: View {
    //Injected
    @Bindable var vm: OnboardingViewModel
    let promptIndex: Int

    //Local view state
    @State private var prompt = PromptResponse(prompt: "", response: "")

    private var key: UserProfile.Field {
        [.prompt1, .prompt2, .prompt3] [promptIndex]
    }
    private var keyPath: WritableKeyPath<DraftProfile, PromptResponse> {
        [\DraftProfile.prompt1, \DraftProfile.prompt2] [promptIndex]
    }

    var body: some View {
        PromptGeneric(prompt: $prompt, promptIndex: promptIndex)
            .nextButton(isValid: prompt.response.count > 3, padding: 24) {
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
                            prompt.response = draft.prompt2.response
                        }
                    }
                }
            }
    }
}

struct EditPrompt: View {
    //Injected
    @Bindable var vm: EditProfileViewModel
    let promptIndex: Int

    //Local view state
    @State private var showEmptyAlert: Bool = false

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
            .checkBeforePop(invalid: check, triggerAlert: $showEmptyAlert)
            .customAlertCard(
                isPresented: $showEmptyAlert,
                title: "Error",
                message: "You Can't leave this prompt empty",
                onOK: {showEmptyAlert.toggle()}
            )
    }
}

struct PromptGeneric: View {
    //Injected
    @Binding var prompt: PromptResponse
    let promptIndex: Int

    //Local view state
    @FocusState var isFocused: Bool
    @State private var showPrompts = false
    private let maxChars = 110
    private let promptTitle: [String] = ["Prompt 1", "Prompt 2", "Prompt 3"]

    private var prompts: [String] {
        let p = Prompts.instance
        return [p.prompts1, p.prompts2, p.prompts3] [promptIndex]
    }

    var body: some View {
        VStack(spacing: Spacing.titleGap) {
            SignUpTitle(text: promptTitle[promptIndex])
            VStack(spacing: Spacing.xl) {
                selector
                textEditor
            }
        }
        .onAppear {
            isFocused = true
            if prompt.prompt.isEmpty {prompt.prompt = prompts.randomElement() ?? "My Ideal Date"}
        }
        .padding(.top, Spacing.lg)
        .padding(.horizontal, Spacing.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fullScreenCover(isPresented: $showPrompts) {SelectPrompt(prompts: prompts, userPrompt: $prompt, promptIndex: promptIndex)}
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appCanvas)
    }
}

extension PromptGeneric {
    private var selector: some View {
        HStack (spacing: Spacing.lg) {
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
        
        PromptInput(text: $prompt.response, isFocused: $isFocused, isPrompt: true)
        
        
        
    }
}

struct PromptInput: View {
    
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    
    let isPrompt: Bool

    //Local view state
    @State private var floorHeight: CGFloat = 0 //Four lines of this field's own type, measured — see `floorTwin`

    //The growing field's floor. Measured rather than computed: a line's height is the font's, and
    //`lineSpacing` only falls BETWEEN lines, so four lines is not four of anything you can multiply
    private static let floorLines = 4
    private static let floorProbe = Array(repeating: "x", count: floorLines).joined(separator: "\n")
    private static let probeWidth: CGFloat = 100 //Geometry: room for the probe's one-letter lines, no more
    //Geometry: the placeholder's own inset — the field is padded to the same, so the two coincide by construction
    private static let textInset = (horizontal: 22.0, vertical: Spacing.lg)

    var placeholderText: String { isPrompt ? "Type your response here" : "Describe the Dream Meetup..."}
    var cornerRadius: CGFloat { isPrompt ? 24 : 16 }
    var height: CGFloat { isPrompt ? 120 : 130 }
    var maxChars: Int { isPrompt ? 110 : 200 }
    var lineLimit: Int { isPrompt ? 3 : 100 }
    
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            editor
                .background(Color.clear)
                .lineSpacing(8)
                .font(.body(17, .medium))
                .focused(isFocused)
                .submitLabel(.done)
                .onChange(of: text) { oldValue, newValue in
                    if newValue.contains(where: \.isNewline) {
                        if newValue.filter({ !$0.isNewline }) == oldValue { //Return, reading Done: closes the keyboard
                            text = oldValue
                            isFocused.wrappedValue = false
                        } else {
                            text = String(newValue.withoutLineBreaks.prefix(maxChars)) //Pasted or dictated
                        }
                    } else if newValue.count > maxChars {
                        text = String(newValue.prefix(maxChars))
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    let remaining = max(0, maxChars - (text.count))
                    if remaining <= 25 {
                        Text("\(remaining)")
                            .font(.body(14))
                            .foregroundStyle(Color.warningYellow)
                            .padding(.trailing, Spacing.sm)
                            .padding(.bottom, Spacing.sm)
                    }
                }
            
            
            if text.isEmpty {
                Text(placeholderText)
                    .font(.body(17, .medium))
                    .foregroundStyle(Color.textPlaceholder)
                // Geometry: match the TextEditor’s visual inset
                    .padding(.horizontal, 22)
                    .padding(.vertical, Spacing.lg)
                    .allowsHitTesting(false)
            }
        }
        .stroke(cornerRadius, lineWidth: 0.5)
    }

    //The prompts keep the box they have: a fixed four-ish lines that scrolls. Ideal Meetup's grows —
    //it stands at four lines and takes a line at a time as the text wraps past them
    @ViewBuilder
    private var editor: some View {
        if isPrompt {
            TextEditor(text: $text)
                .contentMargins(16)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .customScrollFade(height: Spacing.lg, color: .appCanvas, edge: .top, curve: .even)
                .customScrollFade(height: Spacing.lg, color: .appCanvas, edge: .bottom, curve: .even)
                .lineLimit(lineLimit)
        } else {
            TextField("", text: $text, axis: .vertical)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(minHeight: floorHeight, alignment: .top) //The floor sits on the TEXT, so the insets below are clear of it
                //NOT `.contentMargins(16)`: measured on an iPhone 17 Pro (2026-09-20) it is a no-op on a
                //vertical TextField — the text lands flush in the corner. This padding IS the prompts'
                //`contentMargins(16)`, restated: a TextEditor adds its own ~5pt lineFragmentPadding on top
                //of that margin, so 22 here puts the two fields' text on the same line as each other
                .padding(.horizontal, Self.textInset.horizontal)
                .padding(.vertical, Self.textInset.vertical)
                .background(alignment: .topLeading) { floorTwin }
                //A vertical TextField is only as tall as its text — it does NOT fill the box the floor
                //holds open, so without this the box takes taps on its first line alone. The TextEditor
                //filled its frame and gave this away for free
                .contentShape(Rectangle())
                .onTapGesture { isFocused.wrappedValue = true }

        }
    }

    //The same field at `floorLines`, hidden: the height the box holds at when the text is shorter. Its
    //lines never wrap, so a fixed narrow width gives the same answer as the real one — and is typeset
    //once instead of on every keystroke
    private var floorTwin: some View {
        TextField("", text: .constant(Self.floorProbe), axis: .vertical)
            .font(.body(17, .medium))
            .lineSpacing(8)
            .frame(width: Self.probeWidth)
            .fixedSize(horizontal: false, vertical: true)
            .getHeight($floorHeight)
            .hidden()
    }
}

/*
 
 ZStack(alignment: .topLeading) {
     TextEditor(text: $prompt.response)
         .padding()
         .scrollContentBackground(.hidden)
         .frame(maxWidth: .infinity)
         .frame(height: 120)
         .lineSpacing(8)
         .font(.body(17, .medium))
         .focused($isFocused)
         .submitLabel(.done)
         .lineLimit(3)
         .onChange(of: prompt.response) { oldValue, newValue in
             if newValue.contains(where: \.isNewline) {
                 if newValue.filter({ !$0.isNewline }) == oldValue { //Return, reading Done: closes the keyboard
                     prompt.response = oldValue
                     isFocused = false
                 } else {
                     prompt.response = String(newValue.withoutLineBreaks.prefix(maxChars)) //Pasted or dictated
                 }
             } else if newValue.count > maxChars {
                 prompt.response = String(newValue.prefix(maxChars))
             }
         }
         .overlay(alignment: .bottomTrailing) {
             let remaining = max(0, maxChars - (prompt.response).count)
             if remaining <= 25 {
                 Text("\(remaining)")
                     .font(.body(14))
                     .foregroundStyle(Color.warningYellow)
                     .padding(.trailing, Spacing.sm)
                     .padding(.bottom, Spacing.sm)
             }
         }
     
     
     if prompt.response.isEmpty {
         Text("Type your response here")
             .font(.body(17, .medium))
             .foregroundStyle(Color.textPlaceholder)
         // Geometry: match the TextEditor’s visual inset
             .padding(.horizontal, 22)
             .padding(.vertical, Spacing.lg)
             .allowsHitTesting(false)
     }
 }
 .stroke(CornerRadius.lg, lineWidth: 0.5)
 */
