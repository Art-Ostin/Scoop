//
//  EditNameView.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct EditTextFieldView: View {
    
    var title: String
    
    @Binding var textFieldText: String
    
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 120) {
                SignUpTitle(text: title)
                    .padding(.top, 96)
                    .padding(.horizontal, 32)
                
                EditTextField(placeholder: "", textFieldText: $textFieldText, isFocused: $isFocused)
            }
            .onAppear {
                isFocused = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CustomBackButton()
            }
        }
    }
}
