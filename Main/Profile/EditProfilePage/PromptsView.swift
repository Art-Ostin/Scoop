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
        CustomList(title: "Prompts") {
            VStack(spacing: 12) {
                NavigationLink {
                    EditPrompt(vm: vm, promptIndex: 0)
                } label: {
                    promptResponse(prompt: vm.draft.prompt1.prompt, response: vm.draft.prompt1.response)
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    EditPrompt(vm: vm, promptIndex: 1)
                } label: {
                    promptResponse(prompt: vm.draft.prompt2.prompt, response: vm.draft.prompt2.response)
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    EditPrompt(vm: vm, promptIndex: 2)
                } label: {
                    promptResponse(prompt: vm.draft.prompt3.prompt, response: vm.draft.prompt3.response)
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
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
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .padding()
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
            .padding(.horizontal)
    }
}

/*
 .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
 */
