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
    var isLookingFor: Bool = false

    //Local view state
    @State private var floorHeight: CGFloat = 0 //`floorLines` of this field's own type, measured — see `floorTwin`

    //The growing field's floor. Measured rather than computed: a line's height is the font's, and
    //`lineSpacing` only falls BETWEEN lines, so four lines is not four of anything you can multiply.
    //Looking For stands at two: its box holds the first two lines and grows from the third
    private var floorLines: Int { isLookingFor ? 2 : 4 }
    private var floorProbe: String { Array(repeating: "x", count: floorLines).joined(separator: "\n") }
    private static let probeWidth: CGFloat = 100 //Geometry: room for the probe's one-letter lines, no more
    //Geometry: where the text sits in the box — the placeholder and the growing field are both padded to it, so
    //the two coincide by construction. Looking For centres its first line where the option rows above it centre
    //their label: 16 in, and (56 − 17) / 2 down, a 17pt line centred in the 56pt row — 81pt at rest (19.5 + 42 + 19.5)
    private var textInset: (horizontal: CGFloat, vertical: CGFloat) {
        isLookingFor ? (horizontal: Spacing.md, vertical: 19.5) : (horizontal: 22, vertical: Spacing.lg)
    }

    var placeholderText: String { isPrompt ? "Type your response here" : isLookingFor ? "Describe the kind of thing you want" : "Describe the Dream Meetup..."}
    var cornerRadius: CGFloat { isPrompt ? CornerRadius.xl : CornerRadius.md }
    var maxChars: Int { isPrompt || isLookingFor ? 110 : 200 }
    //The prompts' fixed box. Nothing here sizes the growing field — that holds at `floorLines`
    private static let promptHeight: CGFloat = 120
    private static let promptLineLimit = 3
    
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            editor
                .background(isLookingFor ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: cornerRadius))
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
                    .padding(.horizontal, textInset.horizontal) //Geometry: on the field's own text — see `textInset`
                    .padding(.vertical, textInset.vertical)
                    .allowsHitTesting(false)
            }
        }
        .stroke(cornerRadius, lineWidth: 0.5)
    }

    //The prompts keep the box they have: a fixed four-ish lines that scrolls. Ideal Meetup's and Looking
    //For's grow — they stand at `floorLines` (four, two) and take a line at a time as the text wraps past them
    @ViewBuilder
    private var editor: some View {
        if isPrompt {
            TextEditor(text: $text)
                .contentMargins(16)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity)
                .frame(height: Self.promptHeight)
                .customScrollFade(height: Spacing.lg, color: .appCanvas, edge: .top, curve: .even)
                .customScrollFade(height: Spacing.lg, color: .appCanvas, edge: .bottom, curve: .even)
                .lineLimit(Self.promptLineLimit)
        } else {
            TextField("", text: $text, axis: .vertical)
                .textClipDisabled() //ModernEra's accents and descenders overhang its clip: see TextClipDisabler
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(minHeight: floorHeight, alignment: .top) //The floor sits on the TEXT, so the insets below are clear of it
                //NOT `.contentMargins(16)`: measured on an iPhone 17 Pro (2026-09-20) it is a no-op on a
                //vertical TextField — the text lands flush in the corner. This padding IS the prompts'
                //`contentMargins(16)`, restated: a TextEditor adds its own ~5pt lineFragmentPadding on top
                //of that margin, so 22 here puts the two fields' text on the same line as each other.
                //Looking For lines up with its option rows instead — see `textInset`
                .padding(.horizontal, textInset.horizontal)
                .padding(.vertical, textInset.vertical)
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
        TextField("", text: .constant(floorProbe), axis: .vertical)
            .font(.body(17, .medium))
            .lineSpacing(8)
            .frame(width: Self.probeWidth)
            .fixedSize(horizontal: false, vertical: true)
            .getHeight($floorHeight)
            .hidden()
    }
}

// MARK: - Unclipped text

private extension View {
    //ModernEra's accents (Å, É) and descenders (g, y, j) overhang its line box, and a vertical TextField clips its text
    //view to exactly its lines, so they were cut flat on the first and last lines. This lets them draw into the padding.
    //Put it straight on the TextField, before any frame or padding: it finds the text view by sitting exactly over it.
    //Only on a field that grows with its text — a squeezed one scrolls its lines, and they would spill out
    func textClipDisabled() -> some View {
        background(TextClipDisabler())
    }
}

//Finds the text view it sits exactly under and turns its clip off. Fails safe: a field SwiftUI stops hosting in a
//UITextView is left as it was
private struct TextClipDisabler: UIViewRepresentable {

    final class Marker: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            setNeedsLayout()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            DispatchQueue.main.async { [weak self] in self?.disableClip() } //Once SwiftUI has placed the text view too
        }

        private func disableClip() {
            guard let window else { return }
            let frame = convert(bounds, to: window)
            //Origin and width, each within a point: SwiftUI rounds the text view's frame to pixels, and a growing
            //field's height trails the marker's by a pass
            func find(in view: UIView) -> UITextView? {
                if let textView = view as? UITextView {
                    let own = textView.convert(textView.bounds, to: window)
                    if abs(own.minX - frame.minX) < 1, abs(own.minY - frame.minY) < 1, abs(own.width - frame.width) < 1 { return textView }
                }
                //A plain loop: `lazy.compactMap(…).first` evaluates the match twice, doubling the search at every level down
                for subview in view.subviews { if let textView = find(in: subview) { return textView } }
                return nil
            }
            sequence(first: self as UIView, next: \.superview).lazy.compactMap(find(in:)).first?.clipsToBounds = false
        }
    }

    func makeUIView(context: Context) -> Marker {
        let marker = Marker()
        marker.isUserInteractionEnabled = false
        return marker
    }

    func updateUIView(_ uiView: Marker, context: Context) {}
}

