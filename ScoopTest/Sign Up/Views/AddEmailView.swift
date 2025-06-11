//
//  RegisterEmailView.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI

struct AddEmailView: View {
    
    @Environment(ScoopViewModel.self) var viewModel
    @State var email: String = ""
    @FocusState var keyboardFocused: Bool
    
    @State var isAuthorised: Bool = false
    @State var showAlert: Bool = false
    
    
    var body: some View {
        
        ZStack{
            VStack(alignment: .leading){
                
                titleView(text: "McGill Email", count: 0)
                    .padding(.bottom, 72)
                    
                
                enterEmailSection
                
                NextButton(isEnabled: viewModel.EmailIsAuthorised(email: email), onInvalidTap: {showAlert = true})
                    .padding(.top, (100))
                
                alertScreen
            }
        }
        .padding(.top, 148)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            keyboardFocused = true
        }
    }
}


#Preview {
    AddEmailView()
        .environment(ScoopViewModel())
}

extension AddEmailView {
    
    private var enterEmailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                
                ZStack{
                    if email.isEmpty {
                        TextField("Firstname.lastname", text: $email)
                            .font(.custom("ModernEra-MediumItalic", size: 20))
                            .kerning(0.5)
                    }
                    
                    TextField ("", text: $email)
                        .focused($keyboardFocused)
                        .font(.custom("ModernEra-Medium", size: 20))
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .tint(.blue)
                        .kerning(0.5)
                        .foregroundStyle(.black)
                }
                
                Spacer()
                
                Text("@mail.mcgill.ca")
                    .font(.custom("ModernEra-Medium", size: 20))
                    .padding(.trailing, 2)
            }
            HStack {
                Rectangle()
                    .frame(width: 200, height: 1)
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

