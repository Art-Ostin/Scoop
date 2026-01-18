//
//  EditSex.swift
//  Scoop
//
//  Created by Art Ostin on 21/11/2025.
//

import SwiftUI

struct OnboardingSex: View {
    @Bindable var vm: OnboardingViewModel
    @State var text: String = ""
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
    
    let grid = [GridItem(.flexible()), GridItem(.flexible())]
    let options = ["Male", "Female", "Type my Sex"]
    let isOnboarding: Bool
    @Binding var selectedOption: String
    @State var showTypeSexField : Bool = false
    
    var customisedSex: Bool {
        return !selectedOption.isEmpty && !options.contains(selectedOption)
    }
    @State private var keyPressToken = 0
    @State private var hasEditedThisSession = false
    @State var showSaved: Bool = false
    let onTap: (String) -> Void
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 84) {
            SignUpTitle(text: "Sex")
            
            VStack(alignment: .leading, spacing: 48) {
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
                        NextButton(isEnabled: true) {
                            onTap(selectedOption)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .sheet(isPresented: $showTypeSexField) {
            TextFieldGeneric(text: $selectedOption, field: "Your Gender")
                .presentationBackground(Color.background)
                .padding(.top, 48)
                .overlay(alignment: .topTrailing) {
                    if showSaved {
                        saveIcon
                    }
                    
                }
                .overlay(alignment: .top) {
                    doneButton //96 is how much padding the text field has, then position done button 72 beneath
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
        .background (Color.background)
    }
}
extension GenericSex {
    
    private var rubbishBin: some View {
        Image(systemName: "trash")
            .foregroundStyle(.black)
            .font(.system(size: 16))
            .frame(width: 45)
            .padding(4)
            .background(
                Circle()
                    .fill(Color.clear)
                    .stroke(100, lineWidth: 0.5, color: .black))
            .padding(12)
            .contentShape(Circle())
    }
    
    private var saveIcon: some View {
        HStack(spacing: 12) {

            Text("Saved")
                .font(.body(14, .bold))
                .foregroundStyle(Color(red: 0.16, green: 0.65, blue: 0.27))
            
            Image("GreenTick")
                .offset(y: -2)
        }
        .padding(.top, 72)
        .padding(.horizontal, 36)
    }
    
    private var doneButton: some View {
        
        Button {
            showTypeSexField = false
        } label: {
            Text("Done")
                .padding(.horizontal)
                .padding(.vertical, 8)
                .font(.body(14, .bold))
                .foregroundStyle(Color.accent)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.background)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 2)
                        .stroke(12, lineWidth: 1, color: .black)
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 36)
        }
    }
}
