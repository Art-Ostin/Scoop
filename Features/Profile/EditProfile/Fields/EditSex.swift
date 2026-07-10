//
//  EditSex.swift
//  Scoop
//
//  Created by Art Ostin on 21/11/2025.
//

import SwiftUI

struct OnboardingSex: View {
    @Bindable var vm: OnboardingViewModel
    @State private var text: String = ""
    var body: some View {
        GenericSex(isOnboarding: true, selectedOption: $text) {_ in
            vm.saveAndNextStep(kp: \.sex, to: text)
        }
    }
}

struct EditSex: View {
    @Bindable var vm: EditProfileViewModel
    var selection: Binding<String> {
        Binding { vm.draft.sex} set: { vm.set(.sex, \.sex, to: $0)}
    }
    var body: some View {
        GenericSex(isOnboarding: false, selectedOption: selection) {selection.wrappedValue = $0}
    }
}

struct GenericSex: View {
    
    //Injected
    let isOnboarding: Bool
    @Binding var selectedOption: String
    let onTap: (String) -> Void

    //Local view state
    @State private var showTypeSexField : Bool = false
    @State private var keyPressToken = 0
    @State private var hasEditedThisSession = false
    @State private var showSaved: Bool = false
    private let options = ["Male", "Female", "Type my Sex"]

    var customisedSex: Bool {
        return !selectedOption.isEmpty && !options.contains(selectedOption)
    }

    var body: some View {
        
        VStack(alignment: .leading, spacing: Spacing.titleGap) {
            SignUpTitle(text: "Sex")
            
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                HStack {
                    SexStandardPill(title: options[0], selectedOption: $selectedOption) {
                        onTap(selectedOption)
                    }
                    Spacer()
                    SexStandardPill(title: options[1], selectedOption: $selectedOption) {
                        onTap(selectedOption)
                    }
                }
                
                HStack(spacing: 0) {
                    if customisedSex {
                        SexOptionPill(gender: $selectedOption, editText: $showTypeSexField)
                        Button { withAnimation { selectedOption = ""} } label: {
                            rubbishBin
                        }
                    } else {
                        SexStandardPill(title: options[2], selectedOption: $selectedOption) {
                            selectedOption = ""
                            showSaved = false
                            showTypeSexField = true
                        }
                    }
                    if isOnboarding && customisedSex {
                        NextButton(isValid: true) {
                            onTap(selectedOption)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.margin)
        .padding(.bottom, Spacing.lg)
        .sheet(isPresented: $showTypeSexField) {
            TextFieldGeneric(text: $selectedOption, field: "Your Gender")
                .presentationBackground(Color.appCanvas)
                .padding(.top, Spacing.xxl)
                .overlay(alignment: .topTrailing) {
                    if showSaved {
                        SavedIcon(topPadding: 72, horizontalPadding: 36, isSettings: false)
                    }
                    
                }
                .overlay(alignment: .top) {
                    doneButton //Geometry: 96 is how much padding the text field has, then position done button 72 beneath
                        .padding(.top, 396)
                }
                .onAppear {
                    hasEditedThisSession = false
                    showSaved = false
                }
                .onChange(of: selectedOption) {
                    hasEditedThisSession = true
                    keyPressToken &+= 1
                }
                .task(id: selectedOption) {
                    withAnimation(.smooth()) { showSaved = false }
                    guard hasEditedThisSession else { return }
                    if keyPressToken != 0 {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        withAnimation(.smooth()) { showSaved = true }
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background (Color.appCanvas)
    }
}
extension GenericSex {
    
    private var rubbishBin: some View {
        Image(systemName: "trash")
            .foregroundStyle(Color.textPrimary)
            .font(.system(size: 16))
            .frame(width: 45)
            .padding(Spacing.xxs)
            .background(
                Circle()
                    .fill(Color.clear)
                    .capsuleStroke(lineWidth: 0.5, color: .black))
            .padding(Spacing.sm)
            .contentShape(Circle())
    }
    
    private var doneButton: some View {
        
        Button {
            showTypeSexField = false
        } label: {
            Text("Done")
                .padding(.horizontal)
                .padding(.vertical, Spacing.xs)
                .font(.body(14, .bold))
                .foregroundStyle(Color.accent)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.appCanvas)
                        .shadow(.button)
                        .stroke(CornerRadius.sm, lineWidth: 1, color: .black)
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, Spacing.xl)
        }
    }
}
