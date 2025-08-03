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
        
        
        VStack(alignment: .leading, spacing: 48) {
            
            VStack(spacing: 12) {
                HStack() {
                    Text(vm.event.type?.description.label ?? "")
                        .font(.body(16, .bold))
                    Image(systemName: "chevron.down")
                        .font(.body(14, .bold))
                        .foregroundStyle(.accent)
                } .onTapGesture {vm.showTypePopup.toggle()}
                    .popover(isPresented: $vm.showTypePopup, arrowEdge: .top) {
                        SelectTypeView(vm: $vm)
                            .frame(maxWidth: 250) // adjust as needed
                    }
            }
            
            TextEditor(text: Binding(
                get: { vm.event.message ?? ""},
                set: { vm.event.message = $0}
            ))
            .background(Color.clear)
            .font(.body(18))
            .focused($isFocused)
        }
        
        
        
         
         
         
         
         
         
         
         
         
         
         ZStack {
             
             VStack(alignment: .leading, spacing: 48) {
                 
                 
                 ZStack {
                     
                     if vm.event.message == nil {
                         Text("Write a message here to give some info about the meet-up")
                             .foregroundStyle(Color(red: 0.73, green: 0.73, blue: 0.73))
                             .font(.body(18))
                             .lineSpacing(6)
                             .frame(maxHeight: .infinity, alignment: .top)
                             .offset(x: 5)
                             .offset(y: 10)
                     }
                     
                 }
                 .padding()
                 .frame(height: 145, alignment: .top)
                 .frame(maxWidth: .infinity, alignment: .topLeading)
                 .overlay (
                     RoundedRectangle(cornerRadius: 18)
                         .stroke(Color.gray, lineWidth: 1)
                 )
                 
                
                 
                 
             }
             .frame(maxWidth: .infinity, alignment: .leading)
             .padding()
             
             if vm.showTypePopup {
                 SelectTypeView(vm: $vm)
             }
         }
         .onAppear {
             isFocused = true
         }
     }
 }

// #Preview {
//     InviteAddMessageView(typeInputText: .constant(""), typeDefaultOption: .constant("Grab food"), showTypePopup: .constant(false))
// }

