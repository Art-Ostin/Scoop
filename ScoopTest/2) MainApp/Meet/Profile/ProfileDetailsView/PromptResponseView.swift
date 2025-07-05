//
//  PromptResponseView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct PromptResponseView: View {
    
    @Bindable var vm: ProfileViewModel
    
    @State var inviteButton: Bool
    
    
    var body: some View {
            
        VStack {
            
            Text(vm.profile.prompt1.question)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, 16)
                .font(.body(14, .italic))
            
            Text(vm.profile.prompt1.answer)
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
        .overlay(
            InviteButton(vm: vm)
                .padding(.horizontal, 12)
                .offset(y: 24),
            alignment: .bottomTrailing
        )
        .padding(.horizontal, 24)
    }
}


struct PromptResponseView_Previews: PreviewProvider {
    static var previews: some View {
        PromptResponseView(
            vm: ProfileViewModel(),
            inviteButton: false)
        .previewLayout(.sizeThatFits)
    }
}
