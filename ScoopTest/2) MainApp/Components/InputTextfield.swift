//
//  InputTextbox.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct InputTextfield: View {

    
        let placeholder: String
        var inputtedText: Binding<String>
        let textSize: CGFloat
        var isFocused: FocusState<Bool>.Binding
        var alignment: Alignment = .leading
        
        var body: some View {
            
            VStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    if inputtedText.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(.body(textSize, .italic))
                            .padding(.horizontal, alignment == .center ? 22 : 0)
                            .foregroundStyle(.gray)
                            .padding(.leading, 5)
                    }
                    TextField("", text: inputtedText)
                        .font(.body(textSize))
                        .padding(.horizontal, alignment == .center ? 22 : 0)
                        .focused(isFocused)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .tint(.blue)
                        .kerning(0.5)
                        .foregroundStyle(.black)
                }
                Rectangle()
                    .frame(width: 303, height: 1)
                    .foregroundStyle(Color(red: 0.8, green: 0.8, blue: 0.8))
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
    }
