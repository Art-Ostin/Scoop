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
    let promptIndex: Int
    let titles = ["Prompts 1", "Prompts 2", "Prompts 3"]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ForEach(prompts, id: \.self) {text in
                    PromptRow(text: text, prompt: $userPrompt)
                }
            }
            .padding(.top, Spacing.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .scrollContentBackground(.hidden)
            .padding(.leading, Spacing.margin)
            .background(Color.white)
            .toolbar {
                DismissToolbarItem(type: .cross, isLeading: false)
            }
            .navigationTitle(titles[promptIndex])
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
        VStack(spacing: Spacing.lg) {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(isSelected ? Color.textAccent : Color.textPrimary)
                .font(.body(16, prompt.prompt == text ? .bold : .medium))

            RoundedRectangle(cornerRadius: CornerRadius.md)
                .frame(height: 1, alignment: .leading)
                .foregroundStyle(Color.border)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .onTapGesture {
            prompt.prompt = text
            dismiss()
        }
    }
}
