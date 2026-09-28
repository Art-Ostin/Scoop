//
//  EditLookingFor.swift
//  Scoop
//
//  Created by Art Ostin on 21/09/2026.
//

import SwiftUI



struct OnboardingLookingFor: View {
    
    @Bindable var vm: OnboardingViewModel
    
    @State private var lookingFor = ""
    @State private var lookingForText = ""
    
    var body: some View {
        
        GenericLookingFor(lookingFor: $lookingFor, lookingForText: $lookingForText)
            .contentMargins(.bottom, Spacing.clearance, for: .scrollContent) //A short phone scrolls the box clear of Next
            .nextButton(isValid: !lookingFor.isEmpty, padding: Spacing.lg) {
                vm.saveAndNextStep(kp: \.lookingForText, to: lookingForText, updateOnly: true)
                vm.saveAndNextStep(kp: \.lookingFor, to: lookingFor)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                if let draft = vm.draftProfile {
                    lookingFor = GenericLookingFor.option(for: draft.lookingFor)
                    lookingForText = draft.lookingForText
                }
            }
    }
}

struct EditLookingFor: View {
    
    let vm: EditProfileViewModel

    @State private var lookingFor: String
    @State private var lookingForText: String
    
    @State private var showIncompleteAlert = false
    
    init(vm: EditProfileViewModel) {
        self.vm = vm
        _lookingFor = .init(initialValue: GenericLookingFor.option(for: vm.draft.lookingFor))
        _lookingForText = .init(initialValue: vm.draft.lookingForText)
    }

    var body: some View {
        GenericLookingFor(lookingFor: $lookingFor, lookingForText: $lookingForText)
            .onDisappear { savePreferences() }
            .checkBeforePop(invalid: lookingFor.isEmpty, triggerAlert: $showIncompleteAlert) { savePreferences() }
            .customAlertCard(
                isPresented: $showIncompleteAlert,
                title: "Error",
                message: "Please choose what you're looking for",
                onOK: { showIncompleteAlert.toggle() }
            )
    }

    //Writes only what changed: an untouched legacy value shows as its new option, and writing that back
    //would mark the profile edited just for opening the screen. A second call (the pop, then disappear) writes nothing
    private func savePreferences() {
        if lookingFor != GenericLookingFor.option(for: vm.draft.lookingFor) {
            vm.set(.lookingFor, \.lookingFor, to: lookingFor)
        }
        if lookingForText != vm.draft.lookingForText {
            vm.set(.lookingForText, \.lookingForText, to: lookingForText)
        }
    }
}





struct GenericLookingFor: View {
    
    @Binding var lookingFor: String
    @Binding var lookingForText: String
    
    @FocusState var isFocused: Bool
    
    let selectedTexts: [String] = [
        "Long Term Relationship",
        "Short Term Relationship",
        "Something Casual",
        "Long Term, open to Short",
        "Short Term, open to Long",
        "Still deciding"
    ]

    var body: some View {
        content
            .keyboardDoneButton(isFocused: $isFocused, hide: .dismiss)
            .background(Color.appCanvas.ignoresSafeArea())
    }

    //The values profiles already carry from the three-option Seeking picker this screen replaces
    private static let legacyOptions: [String: String] = [
        "Long-term": "Long Term Relationship",
        "Short-term": "Short Term Relationship",
        "Undecided": "Still deciding",
    ]

    //The row a stored value selects: a legacy value lands on its new option, anything else as it is
    static func option(for stored: String) -> String {
        legacyOptions[stored] ?? stored
    }
}

//Main Content Screen
extension GenericLookingFor {

    private static let optionsReturnLag: TimeInterval = 0.15 //As EditIdealMeetup's chipsReturnLag: the field settles, then the rows return

    private var content: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                SignUpTitle(text: "Looking For")

                VStack(spacing: Spacing.md) { //The gap of the time-cell list these rows are drawn from
                    if !isFocused { //Focused, the rows leave and the field rises into the first row's place; the title never moves
                        ForEach(selectedTexts, id: \.self) { text in
                            selectionIcon(text: text)
                        }
                        .transition(.asymmetric( //On each row, so each pops where it stands — the 416pt block at 0.7 would cave in 62pt
                            insertion: .blurPop().animation(.transition.delay(Self.optionsReturnLag)),
                            removal: .blurPop()))
                    }
                    customTextFieldBox
                }
            }
            .animation(.selectionDot, value: lookingFor) //ring, dot, card stroke and label all land together
            .padding(.top, Spacing.lg)
            .padding(.horizontal, Spacing.margin)
            .instantPressDelivery() //Inside a scroll the rows' press would otherwise land ~150ms late
        }
        .scrollBounceBehavior(.basedOnSize) //Holds still wherever the column fits; only a short phone scrolls
        .animation(.keyboard, value: isFocused) //one transaction: the rows leave, the field rises, and a scrolled column settles with them
    }

    //A row picks `lookingFor`; the box below is the separate free text, so neither overwrites the other
    private func selectionIcon(text: String) -> some View {
        Button  {
            lookingFor = text
        } label: {
            sectionLabel(text: text, isSelected: text == lookingFor)
        }
        .shrinkButton() //As the time cell these rows are drawn from: a wide card takes the subtle press
    }
    
    private func sectionLabel(text: String, isSelected: Bool) -> some View {
        HStack(spacing: Spacing.md) {
            optionText(text: text, isSelected: isSelected)
            Spacer()
            selectedIcon(isSelected: isSelected)
        }
        .frame(maxWidth: .infinity)
        .invitedTimeCellBackground(isSelected: isSelected, isActive: true, isLookingFor: true)
    }
    
    private func optionText(text: String, isSelected: Bool) -> some View {
        Text(text)
            .font(.body(16,  isSelected ? .bold : .medium))
            .foregroundStyle(Color.textPrimary)
    }
    
    private func selectedIcon(isSelected: Bool) -> some View {
        Color.clear //not a bare Circle(): a Shape used as a View fills with whatever foreground it inherits
            .frame(width: 20, height: 20)
            .circleStroke(lineWidth: 1.2, color: isSelected ? Color.accent : Color.borderLight)
            .overlay {
                Circle()
                    .fill(Color.accent)
                    .frame(width: 10, height: 10)
                    .scaleEffect(isSelected ? 1 : 0.30)
                    .opacity(isSelected ? 1 : 0)
            }
    }
}

extension GenericLookingFor {
    
    @ViewBuilder
    private var customTextFieldBox: some View {
        let notEmpty = lookingForText.isEmpty == false
        
            PromptInput(text: $lookingForText, isFocused: $isFocused, isPrompt: false, isLookingFor: true)
                .allowsHitTesting(isFocused)
                .overlay(alignment: .topTrailing) {
                    if !isFocused {
                        Image(notEmpty ? "EditGray" : "EditButton")
                            .padding()
                            .scaleEffect(notEmpty ? 0.8 : 1, anchor: .topTrailing)
                            .transition(.asymmetric(
                                insertion: .blurPop().animation(.transition.delay(Self.optionsReturnLag)),
                                removal: .blurPop()))
                    }
                }
                .subtleShrinkPress(isEnabled: !isFocused) { isFocused = true } //Focused, it stands down: a tap places the caret, never shrinks the box
        }
}
