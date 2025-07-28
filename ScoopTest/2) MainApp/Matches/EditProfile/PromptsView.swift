//
//  Prompts.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct PromptsView: View {
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    @Binding var vm: EditProfileViewModel
    
    var body: some View {
        
        let currentUser = dependencies.userStore.user
        

        CustomList(title: "Prompts") {
            VStack(spacing: 12) {
                NavigationLink {
                    EditPrompt(prompts: Prompts.instance.prompts1, promptIndex: 1)
                } label: {
                    promptResponse(prompt: currentUser?.prompt1?.prompt ?? "Add Prompt", response: currentUser?.prompt1?.response ?? "")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    EditPrompt(prompts: Prompts.instance.prompts2, promptIndex: 2)
                } label: {
                    promptResponse(prompt: currentUser?.prompt2?.prompt ?? "Add Prompt", response: currentUser?.prompt2?.response ?? "")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    EditPrompt(prompts: Prompts.instance.prompts3, promptIndex: 3)
                } label: {
                    promptResponse(prompt:currentUser?.prompt3?.prompt ?? "Add Prompt", response: currentUser?.prompt3?.response ?? "")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 32)
    }
}

//#Preview {
//    PromptsView()
//}

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
            .frame(width: 340, height: 130, alignment: .topLeading)
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
            .padding(.horizontal)
            .lineSpacing(8)
    }
}
