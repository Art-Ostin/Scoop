//
//  RegisterEmailView.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//
import Foundation
import SwiftUI

struct EnterEmailView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appDependencies) private var dependencies
    
    @State var showVerification: Bool = false
    @State var vm: EmailVerificationViewModel
    
    @FocusState private var isFocused: Bool
    @Binding var showLogin: Bool
    @Binding var showEmail: Bool
    
    init(dep: AppDependencies, showLogin: Binding<Bool>, showEmail: Binding<Bool>) {
        self._vm = State(initialValue: EmailVerificationViewModel(authManager: dep.authManager))
        self._showLogin = showLogin
        self._showEmail = showEmail
    }
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 72) {
                SignUpTitle(text: "McGill Email")
                VStack(spacing: 96){
                    enterEmailSection
                    NextButton(isEnabled: vm.authoriseEmail(email: vm.username), onTap: {
                        showVerification = true
                    })
                }
                .padding(.horizontal)
            }
            .onAppear {
                isFocused = true
            }
            .frame(maxHeight: .infinity, alignment:.top)
            .padding(.top, 96)
            .padding(.horizontal)
            .background(Color.background)
            .ignoresSafeArea(.keyboard)
            .navigationDestination(isPresented: $showVerification, destination: {EmailVerificationView(vm: $vm, showLogin: $showLogin, showEmail: $showEmail)})
            .navigationBarBackButtonHidden(true)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { NavButton(.cross)} }
        }
    }
}
//#Preview {
//    EnterEmailView(dep: AppDependencies, showLogin: .constant(true), showEmail: .constant(false))
//}


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
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .tint(.blue)
                        .kerning(0.5)
                        .foregroundStyle(.black)
                }
                
                Spacer()
                
                Text("@mail.mcgill.ca")
                    .font(.body(20, .medium))
                    .padding(.trailing, 2)
            }
            HStack {
                Rectangle()
                    .frame(width: 182, height: 1)
                    .foregroundStyle(Color.grayPlaceholder)
                Spacer()
                Rectangle()
                    .frame(width: 140, height: 1)
                    .foregroundStyle(Color.grayPlaceholder)
            }
            Text("We'll send a confirmation code")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
