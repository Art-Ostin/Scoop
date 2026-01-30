//
//  InviteAddMessageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

 
 import SwiftUI

struct AddMessageView: View {
    
    @Binding var vm: TimeAndPlaceViewModel
    @FocusState var isFocused: Bool
    @State var showTypePopup: Bool = false
    
    private var messageBinding: Binding<String> {
        Binding(
            get: { vm.event.message ?? "" },
            set: { vm.event.message = $0 }
        )
    }

    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 72) {
            HStack {
                Text("Add Message")
                    .font(.custom("SFProRounded-Bold", size: 24))
                
                Spacer()
                
                DropDownView(showOptions: $showTypePopup) {
                    dropdownTitle
                } dropDown: {
                    SelectTypeView(vm: vm, selectedType: vm.event.type, showTypePopup: $showTypePopup)
                }
            }
            .frame(maxWidth: .infinity)
            .zIndex(1)
            
            TextEditor(text: messageBinding)
                .padding()
                .background(Color.clear).zIndex(0)
                .font(.body(18))
                .focused($isFocused)
                .lineSpacing(CGFloat(3))
                .frame(maxWidth: .infinity)
                .frame(height: 130)
                .stroke(12, lineWidth: 1, color: .grayPlaceholder)
            
            
            OkDismissButton()
                .padding(.bottom, 36)
        }
        .padding(.top, 84)
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    /*
     .task {
         await Task.yield()
         isFocused = true
     }
     */
}

extension AddMessageView {
    
    @ViewBuilder
    private var dropdownTitle: some View {
        let emoji = vm.event.type?.description.emoji ?? ""
        let type = vm.event.type?.description.label ?? "Select"
        
        HStack(spacing: 10) {
            Text("\(emoji) \(type)")
                .foregroundStyle(.black)
                .font(.body(17))
                .contentShape(.rect)
                .onTapGesture {
                    showTypePopup = true
                }
            
            DropDownButton(isExpanded: $showTypePopup)
        }
    }
}


/*
 
 
 
 
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
 
 OkDismissButton()
}
.onAppear {
 isFocused = true
}
.frame(maxHeight: .infinity, alignment: .top)
.padding(.top, 72)

 */
