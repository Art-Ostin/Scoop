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
    @Environment(\.dismiss) private var dismiss
    @State var vm: VerifyEmailViewModel

    //Local view state
    @State private var showVerification: Bool = false
    @FocusState private var isFocused: Bool

    init(vm: VerifyEmailViewModel) { self._vm = State(initialValue: vm)}
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 72) {
                SignUpTitle(text: "McGill Email")
                enterEmailSection
                NextButton(isValid: vm.isValid(email: vm.username)) {showVerification = true }.padding(.top, 16)
            }
            .padding(.horizontal)
            .onAppear {isFocused = true}
            .frame(maxHeight: .infinity, alignment:.top)
            .padding(.top, 96)
            .padding(.horizontal)
            .background(Color.appCanvas)
            .ignoresSafeArea(.keyboard)
            .navigationDestination(isPresented: $showVerification, destination: {VerifyEmailView(vm: vm)})
            .toolbar { DismissToolbarItem(type: .back)}
        }
    }
}


extension EnterEmailView {
    
    private var enterEmailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack{
                    if vm.username.isEmpty {
                        TextField("Firstname.lastname", text: $vm.username)
                            .font(.body(18, .italic))
                            .kerning(0.5)
                    }
                    TextField ("", text: $vm.username)
                        .focused($isFocused)
                        .font(.body(20))
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .tint(.blue)
                        .kerning(0.5)
                        .foregroundStyle(Color.textPrimary)
                }
                
                Spacer()
                
                Text("@mail.mcgill.ca")
                    .font(.body(20, .medium))
                    .padding(.trailing, 2)
            }
            HStack {
                Rectangle()
                    .frame(width: 182, height: 1)
                    .foregroundStyle(Color.textPlaceholder)
                Spacer()
                Rectangle()
                    .frame(width: 140, height: 1)
                    .foregroundStyle(Color.textPlaceholder)
            }
            Text("We'll send a confirmation code")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
