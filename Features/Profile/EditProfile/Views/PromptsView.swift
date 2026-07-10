//
//  Prompts.swift
//  Scoop
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct PromptsView: View {
    
    @Bindable var vm: EditProfileViewModel
    
    var body: some View {
        let prompts: [PromptResponse] = [ vm.draft.prompt1, vm.draft.prompt2, vm.draft.prompt3,]
        CustomList(title: "Prompts") {
            VStack(spacing: Spacing.sm) {
                ForEach(prompts.indices, id: \.self) { i in
                    NavigationLink(value: EditProfileRoute.prompt(i)) {
                        promptResponse(prompt: prompts[i].prompt, response: prompts[i].response)
                            .foregroundStyle(Color.textPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, 16)
        }
    }
}

extension PromptsView {
    
    @ViewBuilder
    private func promptResponse (prompt: String, response: String) -> some View {
        let isEmpty = response.isEmpty
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(isEmpty ? "Add Prompt" : prompt)
                    .foregroundStyle(isEmpty ? Color.textAccent : Color.textTertiary)
                    .font(.body(14))

                Text(response)
                    .font(.title(response.count < 80 ? 24 : 16 ))
            }
            .font(.body())
            .padding()
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .background(Color.white, in: .rect(cornerRadius: CornerRadius.sm))
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.sm).stroke( isEmpty ? .accent : Color.border, lineWidth: 0.5))
            .overlay(alignment: .topTrailing, content: {
                Image(isEmpty ? "EditButton" : "EditGray")
                    .padding()
            })
            .lineSpacing(8)
    }
}

/*
 .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
 */
