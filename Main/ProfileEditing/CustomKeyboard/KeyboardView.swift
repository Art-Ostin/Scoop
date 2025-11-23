//
//  KeyboardView.swift
//  Scoop
//
//  Created by Art Ostin on 23/11/2025.
//

import SwiftUI

struct KeyboardView: View {
    @State private var text: String = ""
    @FocusState private var isActive: Bool

    var body: some View {
        NavigationStack {
            CustomTextFieldWithKeyboard {
                TextField("App Pin Code", text: $text)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .frame(width: 150)
                    .background(.fill, in: .rect(cornerRadius: 12))
                    .focused($isActive)
            } keyboard: {
                CustomKeyboardView(text: $text, isActive: $isActive)
            }
            .navigationTitle("Custom Keyboard")
        }
    }
}

struct CustomKeyboardView: View {
    @Binding var text: String
    @FocusState.Binding var isActive: Bool

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(spacing: 0), count: 3), spacing: 15) {
            ForEach(1...9, id: \.self) { index in
                ButtonView("\(index)")
            }
            ButtonView("delete.backward.fill", isImage: true)
            ButtonView("0")
            ButtonView("delete.backward.fill", isImage: true)
        }
        .padding(15)
        .background(
            .background.shadow(
                .drop(color: .black.opacity(0.08), radius: 5, x: 0, y: -5)
            )
        )
    }

    @ViewBuilder
    func ButtonView(_ value: String, isImage: Bool = false) -> some View {
        Button {
            if isImage {
                if value == "" && !text.isEmpty {
                    //Delete last character
                    text.removeLast()
                }
                
                if value == "checkmark.circle.fill" {
                    //Verify password here
                    isActive = false
                }
            } else {
                text += value
            }
        } label: {
            

#Preview {
    KeyboardView()
}
