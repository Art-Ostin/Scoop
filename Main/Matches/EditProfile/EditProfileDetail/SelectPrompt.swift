//
//  SelectPrompt.swift
//  Scoop
//
//  Created by Art Ostin on 28/10/2025.
//

import SwiftUI

struct SelectPrompt: View {
    let prompts: [String]
    @Binding var userPrompt: PromptResponse
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(prompts, id: \.self) {text in
                    PromptRow(text: text, prompt: $userPrompt)
                }
            }
            .padding(.top, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .scrollContentBackground(.hidden)
            .padding(.leading, 24)
            .background(Color.white)
            .toolbar {
                CloseToolBar(imageString: "chevron.down", isLeading: false)
            }
            .navigationTitle("Prompts 1")
        }
    }
}

struct PromptRow : View {
    @Environment(\.dismiss) private var dismiss
    let text: String
    
    var isSelected : Bool {
        prompt.prompt == text
    }
    @Binding var prompt: PromptResponse
    
    var body: some View {
        VStack(spacing: 20) {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(isSelected ? .accent : .black)
                .font(.body(16, prompt.prompt == text ? .bold : .medium))

            RoundedRectangle(cornerRadius: 16)
                .frame(height: 1, alignment: .leading)
                .foregroundStyle(Color.gray.opacity(0.2))
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .onTapGesture {
            prompt.prompt = text
            dismiss()
        }
    }
}
