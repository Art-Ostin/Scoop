//
//  Prompts.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct PromptsView: View {
    
    @Bindable var vm: EditProfileViewModel
    
    var body: some View {
        let prompts: [PromptResponse] = [ vm.draft.prompt1, vm.draft.prompt2, vm.draft.prompt3,]
        CustomList(title: "Prompts") {
            VStack(spacing: 12) {
                ForEach(prompts.indices, id: \.self) { i in
                    NavigationLink(value: EditProfileRoute.prompt(i)) {
                        promptResponse(prompt: prompts[i].prompt, response: prompts[i].response)
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
    }
}

extension PromptsView {
    
    private func promptResponse (prompt: String, response: String) -> some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(prompt)
                    .foregroundStyle(Color.grayText)
                    .font(.body(14))
                Text(response)
                    .font(.title(response.count < 80 ? 24 : 16 ))
            }
            .font(.body())
            .padding()
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 1)
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 0.5))
            .overlay(alignment: .topTrailing, content: {
                Image(prompt == "Add Prompt" ? "EditButton" : "EditGray")
                    .padding()
            })
            .lineSpacing(8)
    }
}

/*
 .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
 */
