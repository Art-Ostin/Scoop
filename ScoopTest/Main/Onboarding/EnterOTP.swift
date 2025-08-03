//
//  EnterOTP.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import SwiftUI


struct EnterOTP: View {
    
    @State private var code = ""
    @FocusState private var isFocused: Bool
    
    
    var body: some View {
        ZStack {
            HStack(spacing: 36) {
                ForEach(0..<6, id: \.self) { index in
                    ZStack {
                        Text(digit(at: index))
                            .font(.title)
                        Rectangle()
                            .frame(width: 24, height: 2)
                            .foregroundStyle(Color.grayPlaceholder)
                            .offset(y: 24)
                    }
                }
            }
            
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .frame(width: 0, height: 0)
                .opacity(0)
        }
        .onAppear { DispatchQueue.main.async { isFocused = true } }
    }
    
    private func digit(at index: Int) -> String {
        guard index < code.count else { return "" }
        let start = code.index(code.startIndex, offsetBy: index)
        return String(code[start])
    }
}

#Preview {
    EnterOTP()
}
