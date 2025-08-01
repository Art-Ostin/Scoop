//
//  PromptResponseView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct PromptResponseView: View {
    
    @Bindable var vm: ProfileViewModel
    var prompt: PromptResponse
    
    var body: some View {
        VStack {
            
            Text(vm.p.prompt1?.prompt ?? "")
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, 16)
                .font(.body(14, .italic))
            
            Text(vm.p.prompt1?.response ?? "")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .font(.title(24))
                .lineSpacing(12)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 171)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.78, green: 0.78, blue: 0.78), lineWidth: 1)
            
        )
        .overlay(alignment: .bottomTrailing) {
            if vm.showInvite {
                InviteButton(vm: vm)
                    .padding(.horizontal, 12)
                    .offset(y: 24)
            }
        }
        .padding(.horizontal, 24)
    }
}
