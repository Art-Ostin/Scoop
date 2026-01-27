//
//  InviteAddMessageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

 
 import SwiftUI

struct InviteAddMessageView: View {
    
    @Binding var vm: TimeAndPlaceViewModel
    
    @FocusState var isFocused: Bool
    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 72) {
            HStack() {
                Text(vm.event.type?.description.label ?? "Select a type")
                    .font(.body(24, .medium))
                Image(systemName: "chevron.down")
                    .font(.body(24, .medium))
                    .foregroundStyle(.accent)
            }
            .onTapGesture {  vm.showTypePopup.toggle() }
            
            ZStack {
                TextEditor(text: Binding(
                    get: { vm.event.message ?? ""},
                    set: { vm.event.message = $0}
                ))
                
                if (vm.event.message ?? "").isEmpty {
                    Text("Write a message here to give some info about the meet-up")
                        .foregroundStyle(Color.grayPlaceholder)
                        .offset(x: 9, y: -19)
                        .allowsHitTesting(false)
                        .font(.body(.regular))
                        .lineSpacing(8)
                }
            }
            .padding()
            .background(Color.clear)
            .font(.body(18))
            .focused($isFocused)
            .lineSpacing(CGFloat(3))
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background (RoundedRectangle(cornerRadius: 12).stroke(Color.grayPlaceholder, lineWidth: 1))
        }
        .padding(.top, 24)
        .padding(.horizontal, 32)
        .overlay(alignment: .topLeading) {
            if vm.showTypePopup {
                SelectTypeView(vm: vm, selectedType: vm.event.type)
                    .padding(.top, 12)
            }
        }
        .onAppear {
            isFocused = true
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 72) 
    }
}
