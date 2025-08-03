//
//  InviteAddMessageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

 
 import SwiftUI

struct InviteAddMessageView: View {
    
    @Binding var vm: SendInviteViewModel
    
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 60) {
            
            HStack() {
                Text(vm.event.type?.description.label ?? "")
                    .font(.body(24, .medium))
                Image(systemName: "chevron.down")
                    .font(.body(24, .medium))
                    .foregroundStyle(.accent)
            }
            .onTapGesture { withAnimation { vm.showTypePopup.toggle() } }
            
            TextEditor("Write a message here to give some info about the meet-up", text: Binding(
                get: { vm.event.message ?? ""},
                set: { vm.event.message = $0}
            ))
            .padding()
            .background(Color.clear)
            .font(.body(18))
            .focused($isFocused)
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background (RoundedRectangle(cornerRadius: 12).stroke(Color.grayPlaceholder, lineWidth: 1))
        }
        .padding(.top, 60)
        .padding(.horizontal, 32)
        .overlay(alignment: .topLeading) {
            if vm.showTypePopup {
                SelectTypeView(vm: $vm)
                    .padding(.top, 12)
            }
        }
    }
}
