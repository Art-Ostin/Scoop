//
//  RegisterEmailView.swift
//  Scoop
//
//  Created by Art Ostin on 28/05/2025.
//
import Foundation
import SwiftUI

struct EnterEmailView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    
    //Injected
    @State var vm: VerifyEmailViewModel

    //Local view state
    @State private var showVerification: Bool = false
    @State private var isFocused = true
    @State private var isDismissing = false

    init(vm: VerifyEmailViewModel) { self._vm = State(initialValue: vm)}
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 72) {
                SignUpTitle(text: "McGill Email")
                enterEmailSection
            }
            .padding(.horizontal, 24)
            .onAppear {
                guard !showVerification else { return }
                activateKeyboard()
            }
            .frame(maxHeight: .infinity, alignment:.top)
            .padding(.top, 96)
            .background(Color(red: 1, green: 1, blue: 0.98))
            .navigationDestination(isPresented: $showVerification, destination: {VerifyEmailView(vm: vm)})
            .sheetKeyboardOverlap(
                isFocused: $isFocused,
                isDismissing: $isDismissing
            ) {
                newNextButton
            }
            .overlay(alignment: .topTrailing) { dismissButton}
        }
        .onDisappear { dismissKeyboard() }
        .interactiveDismissDisabled(vm.isVerifying)
    }
}


extension EnterEmailView {
    
    private var nextButton: some View {
        WideActionButton(text: "Send Code", isActive: vm.isValid(email: vm.username)) {
            openVerification()
        }
        .padding(.bottom, 16)
        .padding(.horizontal)
    }
    
    private var newNextButton: some View {
        NextButton(isValid: vm.isValid(email: vm.username)) {
            openVerification()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    
    private var dismissButton: some View {
        Button {
            dismissKeyboard()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.body(12, .bold))
                .foregroundStyle(Color.textTertiary.opacity(0.5))
                .frame(width: 30, height: 30)
                .background(Color(red: 0.95, green: 0.94, blue: 0.95), in: Circle())
                .padding()
                .scaleEffect(0.9)
                .padding(.top, 12)
        }
        .growButton()
    }
    
    private var enterEmailSection: some View {
        let fieldHeight: CGFloat = 48
        let fieldFont = UIFont.body(17, .medium)
        let vInset = (fieldHeight - fieldFont.lineHeight) / 2   //Geometry: centers one text line in the field
        return InstantKeyboardField(
            text: $vm.username,
            font: fieldFont,
            textContainerInset: .init(top: vInset, left: Spacing.md, bottom: vInset, right: Spacing.md),
            isFocused: $isFocused
        )
            .frame(maxWidth: .infinity)
            .frame(height: fieldHeight)
            .background(Color(red: 0.97, green: 0.97, blue: 0.96), in: .rect(cornerRadius: CornerRadius.sm))
            .overlay(alignment: .leading) { if vm.username.isEmpty { placeholder}}
            .overlay(alignment: .trailing) {emailSection}
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .tint(.blue)
            .kerning(0.5)
            .sheetKeyboardOverlapTarget()
    }
    
    private var placeholder: some View {
        Text("firstname.lastname")
            .font(.body(17, .medium))
            .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
            .padding(.leading, Spacing.md)
    }
    
    private var emailSection: some View {
        HStack {
            Text("@mail.mcgill.ca")
                .font(.body(17, .medium))
                .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
                .scaleEffect(0.8, anchor: .trailing)
            
            Image(systemName: "chevron.down")
                .font(.body(12, .bold))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
        }
        .padding(.trailing, Spacing.md)
    }
    
    
    private func activateKeyboard() {
        isDismissing = false
        isFocused = true
    }

    private func dismissKeyboard() {
        InstantKeyboard.dismiss(
            isFocused: $isFocused,
            isDismissing: $isDismissing
        )
    }

    private func openVerification() {
        dismissKeyboard()
        showVerification = true
    }
}
