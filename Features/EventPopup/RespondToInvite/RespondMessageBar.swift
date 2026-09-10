//
//  MessageInputBar.swift
//  Scoop Test
//
//  Created by Art Ostin on 10/09/2026.
//

import SwiftUI

struct RespondToMessageBar: View {
    
    @Binding var text: String
    
    var isFocused: FocusState<Bool>.Binding
    
    private var textLimit: Int { 130 }
    
    var body: some View {
        
        chatTextField
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
            .padding(.top, 6)
    }
}

extension RespondToMessageBar {
    
    private var chatTextField: some View {
        TextField("Add a note...", text: $text, axis: .vertical)
            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)
            .lineSpacing(2.5)
            .lineLimit(1...4)
            .focused(isFocused)
            .onChange(of: text) { _, newValue in
                if newValue.count > textLimit {
                    text = String(newValue.prefix(textLimit))
                }
            }
            .overlay(alignment: .bottomTrailing) { countRemainingText }
            .glassEffectIfAvailable(interactive: true, shape: RoundedRectangle(cornerRadius: CornerRadius.xl))
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
            .onTapGesture { isFocused.wrappedValue = true }
    }
    
    @ViewBuilder
     private var countRemainingText: some View {
         let remaining = max(0, textLimit - text.count)
         if remaining <= 25 {
             Text("\(remaining)")
                 .font(.body(14))
                 .foregroundStyle(Color.warningYellow)
                 .padding(.trailing, Spacing.sm)
                 .padding(.bottom, Spacing.sm)
         }
     }
}
