//
//  HomeTownView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/06/2025.
//

import SwiftUI

struct HomeTownView: View {
    
    @State var hometown: String = ""
    @FocusState var keyboardFocused: Bool
    @State var isSelected: Bool = false
    @State var showAlert: Bool = false
    @Environment(ScoopViewModel.self) private var viewModel
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            titleView(text: "Where do You Live", count: 0)
                .padding(.top, 156)
                .padding(.bottom, 86)
            
            inputTextBox(placeholder: "HomeTown", inputtedText: $hometown, textSize: 24, isFocused: $keyboardFocused)
            
            submitButton(isEnabled: checkHometown(), onInvalidTap: {})
                .padding(.top, 84)
            
        }
        
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            keyboardFocused = true
        }
    }
    func checkHometown () -> Bool {
        
        if hometown.count < 2 {
            return false
        } else {
            return true
        }
    }
}
#Preview {
    HomeTownView()
        .environment(ScoopViewModel())
}
