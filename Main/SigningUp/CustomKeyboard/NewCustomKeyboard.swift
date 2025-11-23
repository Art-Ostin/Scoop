//
//  NewCustomKeyboard.swift
//  Scoop
//
//  Created by Art Ostin on 23/11/2025.
//

import SwiftUI

import UIKit

private struct KeyboardButton<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Content

    var body: some View {
        Button(action: action) {
            label()
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemFill))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CustomKeyboard: View {
    @Binding var text: String

    private let keyRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(keyRows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        KeyboardButton(action: { text.append(key) }) {
                            Text(key)
                                .frame(minWidth: 0)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                KeyboardButton(action: { text.append(".") }) {
                    Image(systemName: "dot.circle")
                        .frame(minWidth: 0)
                        .padding(.horizontal, 6)
                }

                KeyboardButton(action: { text.append(" ") }) {
                    Text("Space")
                        .frame(minWidth: 0)
                }

                KeyboardButton(action: { text.append("\n") }) {
                    Text("Return")
                        .frame(minWidth: 0)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct CustomKeyboard2: View {
    @State private var text: String = ""

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        VStack(spacing: 20) {
            CustomKeyboardTextField(text: $text, placeholder: "Type here...")
                .padding(.horizontal)
        }
        .padding()
    }
}

private struct CustomKeyboardTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.text = text
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        
        let inputView = UIInputView(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 260), inputViewStyle: .keyboard)
        let hostView = context.coordinator.hostingController.view!
        hostView.translatesAutoresizingMaskIntoConstraints = false
        inputView.addSubview(hostView)
        
        NSLayoutConstraint.activate([
            hostView.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            hostView.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
            hostView.topAnchor.constraint(equalTo: inputView.topAnchor),
            hostView.bottomAnchor.constraint(equalTo: inputView.bottomAnchor)
        ])
        
        textField.inputView = inputView
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        private let parent: CustomKeyboardTextField
        fileprivate let hostingController: UIHostingController<CustomKeyboard>
        
        init(parent: CustomKeyboardTextField) {
            self.parent = parent
            let binding = Binding<String> {
                parent.text
            } set: { newValue in
                parent.text = newValue
            }
            
            hostingController = UIHostingController(rootView: CustomKeyboard(text: binding))
            hostingController.view.backgroundColor = .clear
        }
        
        @objc func textChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
        
    }
}
