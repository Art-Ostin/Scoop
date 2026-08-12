//
//  Prompts.swift
//  Scoop
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI


struct PromptsSection: View {

    //Injected
    @Bindable var vm: EditProfileViewModel
    @Binding var path: [EditProfileRoute]

    private var prompts: [PromptResponse] {
        [vm.draft.prompt1, vm.draft.prompt2, vm.draft.prompt3]
    }

    var body: some View {
        Section {
            ForEach(prompts.indices, id: \.self) { i in
                Button { path.append(.prompt(i)) } label: {
                    promptResponse(prompt: prompts[i].prompt, response: prompts[i].response)
                }
                .listRowInsets(EdgeInsets(top: 20, leading: Spacing.md, bottom: i == 2 ? 20 : Spacing.xxs, trailing: Spacing.md))
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
            }
        } header: {
            Text("Prompts")
                .padding(.leading, -Spacing.sm) //Geometry: negates the header's row inset so it lines up with the large title
        }
    }
}

extension PromptsSection {

    @ViewBuilder
    private func promptResponse(prompt: String, response: String) -> some View {
        let isEmpty = response.isEmpty
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(isEmpty ? "Add Prompt" : prompt)
                .foregroundStyle(isEmpty ? Color.textAccent : Color.textTertiary)
                .font(.body(14))

            Text(response)
                .font(.title(response.count < 80 ? 24 : 16))
        }
        .font(.body())
        .foregroundStyle(Color.textPrimary)
        .padding()
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .background(Color.white, in: .rect(cornerRadius: CornerRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.sm)
            .stroke(isEmpty ? .accent : Color.border, lineWidth: 0.5))
        .overlay(alignment: .topTrailing) {
            Image(isEmpty ? "EditButton" : "EditGray")
                .padding()
        }
        .lineSpacing(8)
    }
}

/*
 .onMove { from, to in vm.movePrompts(from: from, to: to) }
 */
