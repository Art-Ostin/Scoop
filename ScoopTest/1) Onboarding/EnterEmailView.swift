//
//  RegisterEmailView.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI
import Combine
import FirebaseAuth


@Observable class EnterEmailViewModel {
    
    var email: String = ""
    var showAlert: Bool = false

    func EmailIsAuthorised(email: String) -> Bool {
        guard email.count > 4, let dotRange = email.range(of: ".") else {
            return false
        }
        let suffix = email[dotRange.upperBound...]
        return suffix.count >= 2
    }
}

struct EnterEmailView: View {
    
    @State private var vm = EnterEmailViewModel()
    @FocusState private var keyboardFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack{
                SignUpTitle(text: "McGill Email")
                    .padding(.bottom, 60)
                    .padding(.top, 136)
                
                enterEmailSection
                    .padding(.bottom, 60)
                
                NavigationLink {
                    NationalityView()
                } label: {
                    NextButton(isEnabled: vm.EmailIsAuthorised(email: vm.email)) {
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 24)
            .onAppear {
                keyboardFocused = true
            }
        }
    }
}


#Preview {
    EnterEmailView()
}



extension EnterEmailView {
    
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
}


//AlertScreen

//
/*
 private var alertScreen: some View {
     Group {
         if vm.showAlert {
             Text("Format must be: firstname.lastname")
                 .foregroundColor(.red)
                 .font(.caption)
                 .onAppear {
                     DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                         vm.showAlert = false
                     }
                 }
         } else {
             EmptyView()
         }
     }
 }
 */
