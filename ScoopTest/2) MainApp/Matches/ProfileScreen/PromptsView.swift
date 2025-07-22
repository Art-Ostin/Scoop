//
//  Prompts.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct PromptsView: View {
    
    var body: some View {

        CustomList(title: "Prompts") {
            VStack(spacing: 12) {
                NavigationLink {
                    EditPrompt(promptIndex: 1, prompts: Prompts.instance.prompts1, isOnboarding: false)
                } label: {
                    promptResponse(prompt: "Three qualities I look for in a person", response: "Going to a rave with a group of maters and bringing the girl along and then having euphoria afterwards all the while adding more lines to to this text")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    EditPrompt(promptIndex: 2, prompts: Prompts.instance.prompts2, isOnboarding: false)
                } label: {
                    promptResponse(prompt: "Dream Date", response: "Going to a rave with a group of maters and bringing the girl along and then having euphoria afterwards all the while adding more lines to to this text")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    EditPrompt(promptIndex: 3, prompts: Prompts.instance.prompts3, isOnboarding: false)
                } label: {
                    promptResponse(prompt: "Dream Date", response: "Going to a rave with a group of maters and bringing the girl along and then having euphoria afterwards all the while adding more lines to to this text")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    PromptsView()
}

extension PromptsView {
    
    private func promptResponse (prompt: String, response: String) -> some View {
                    
            VStack(alignment: .leading, spacing: 12) {
                
                Text(prompt)
                    .foregroundStyle(Color.grayText)
                    .font(.body(15))
                
                Text(response)
                    .font(.body(14))
                
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
                Image("EditGray")
                    .padding()
            })
            .padding(.horizontal)
            .lineSpacing(8)
    }
}
