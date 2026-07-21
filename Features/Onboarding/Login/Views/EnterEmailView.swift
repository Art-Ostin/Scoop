//
//  RegisterEmailView.swift
//  Scoop
//
//  Created by Art Ostin on 28/05/2025.
//
import Foundation
import SwiftUI

struct EnterEmailView: View {
    //Injected
    @State var vm: VerifyEmailViewModel

    //Local view state
    @State private var showVerification: Bool = false
    @FocusState private var isFocused: Bool

    init(vm: VerifyEmailViewModel) { self._vm = State(initialValue: vm)}
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.titleGap) {
                SignUpTitle(text: "What's Your Uni\nEmail?")
                enterEmailSection
                NextButton(isValid: vm.isValid(email: vm.username)) {showVerification = true }.padding(.top, Spacing.md)
            }
            .padding(.horizontal)
            .onAppear {isFocused = true}
            .frame(maxHeight: .infinity, alignment:.top)
            .padding(.top, Spacing.clearance)
            .background(Color.appCanvas)
            .ignoresSafeArea(.keyboard)
            .navigationDestination(isPresented: $showVerification, destination: {VerifyEmailView(vm: vm)})
            .toolbar { DismissToolbarItem(type: .cross, isLeading: false)}
        }
        .interactiveDismissDisabled(vm.isVerifying)
    }
}


extension EnterEmailView {
    
    
    private var enterEmailSection: some View {
        // The field is a UITextView; line up its typed text with the placeholder
        // overlay exactly — same 16pt left inset, and a top/bottom inset that
        // vertically centers the single line — so the caret starts right where
        // "firstname.lastname" sits.
        let fieldHeight: CGFloat = 48
        let fieldFont = UIFont.body(17, .medium)
        let vInset = (fieldHeight - fieldFont.lineHeight) / 2   //Geometry: centers one text line in the field
        return InstantKeyboardField(
            text: $vm.username,
            font: fieldFont,
            textContainerInset: .init(top: vInset, left: Spacing.md, bottom: vInset, right: Spacing.md)
        )
            .frame(maxWidth: .infinity)
            .frame(height: fieldHeight)
            .background(Color(red: 0.97, green: 0.97, blue: 0.96), in: .rect(cornerRadius: CornerRadius.sm))
            .overlay(alignment: .leading) {
                if vm.username.isEmpty {
                    Text("firstname.lastname")
                        .font(.body(17, .medium))
                        .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
                        .padding(.leading, Spacing.md)
                }
            }
            .overlay(alignment: .trailing) {
                HStack {
                    Text("@mail.mcgill.ca")
                        .font(.body(17, .medium))
                        .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
                    
                    Image(systemName: "chevron.down")
                        .font(.body(12, .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                }
                .padding(.trailing, Spacing.md)
            }
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .tint(.blue)
            .kerning(0.5)
    }
}
