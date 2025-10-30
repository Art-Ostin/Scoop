//
//  EnterOTP.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import SwiftUI

 struct EnterOTP: View {
     
     @Binding var code: String
     @FocusState private var isFocused: Bool
     @State private var showCursor = false
     
     
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
                         
                         if code.count == index {
                             BlinkingCursor()
                         }
                     }
                 }
             }
             TextField("", text: $code)
                 .keyboardType(.numberPad)
                 .focused($isFocused)
                 .frame(width: 0, height: 0)
         }
         .onAppear { DispatchQueue.main.async { isFocused = true } }
     }
     
     private func digit(at index: Int) -> String {
         guard index < code.count else { return "" }
         let start = code.index(code.startIndex, offsetBy: index)
         return String(code[start])
     }
     
     private struct BlinkingCursor: View {
         @State private var isVisible = true

         var body: some View {
             Rectangle()
                 .fill(Color.accent)
                 .frame(width: 2, height: 24)
                 .opacity(isVisible ? 1 : 0)
                 .onAppear {
                     withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                         isVisible.toggle()
                     }
                 }
         }
     }
 }
