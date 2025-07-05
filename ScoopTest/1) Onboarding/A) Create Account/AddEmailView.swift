//
//  RegisterEmailView.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI
import Combine
import FirebaseAuth





@Observable class AddEmailViewModel {
    
     var email: String = ""

    func EmailIsAuthorised(email: String) -> Bool {
        guard email.count > 4, let dotRange = email.range(of: ".") else {
            return false
        }
        let suffix = email[dotRange.upperBound...]
        return suffix.count >= 2
    }
    

}

struct AddEmailView: View {
    
    @State private var vm = AddEmailViewModel()
        
    @FocusState private var keyboardFocused: Bool
    
    @State private var isAuthorised: Bool = false
    
    @State private var showAlert: Bool = false
    
    
    var body: some View {
        

        
        ZStack{
            
            VStack{
                SignUpTitle(text: "McGill Email")
                    .padding(.bottom, 60)
                    .padding(.top, 136)
                
                enterEmailSection
                    .padding(.bottom, 60)   
                
                ActionButton(text: "Send Email") {

                }
                
                NextButton(isEnabled: vm.EmailIsAuthorised(email: vm.email), onInvalidTap: {
                    showAlert = true
                })
                .padding(.top, 72)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            keyboardFocused = true
        }
    }
    
}


#Preview {
    AddEmailView()
        .padding(.horizontal, 32)
        .environment(AppState())
        .offWhite()
}

extension AddEmailView {
    
    private var enterEmailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack{
                    if vm.email.isEmpty {
                        TextField("Firstname.lastname", text: $vm.email)
                            .font(.body(18, .italic))
                            .kerning(0.5)
                    }
                    
                    TextField ("", text: $vm.email)
                        .focused($keyboardFocused)
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
                    .frame(width: 180, height: 1)
                    .cornerRadius(1)
                Spacer()
                Rectangle()
                    .frame(width: 140, height: 1)
            }
            Text("We'll send a confirmation link")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var alertScreen: some View {
        Group {
            if showAlert {
                Text("Format must be: firstname.lastname")
                    .foregroundColor(.red)
                    .font(.caption)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showAlert = false
                        }
                    }
            } else {
                EmptyView()
            }
        }
    }
}
