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
        Section("Prompts") {
            ForEach(prompts.indices, id: \.self) { i in
                Button { path.append(.prompt(i)) } label: {
                    promptResponse(prompt: prompts[i].prompt, response: prompts[i].response)
                }
                .padding(.top, i == 0 ? 16 : 16)
                .padding(.bottom, i == 2 ? 16 : 0)
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: Spacing.xxs, leading: Spacing.md,
                                          bottom: Spacing.xxs, trailing: Spacing.md))
            }
            
            .onMove { from, to in vm.movePrompts(from: from, to: to) }
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
 .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
 
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
             .padding(.horizontal, Spacing.md)
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
 */
