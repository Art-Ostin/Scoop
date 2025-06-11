//
//  FacultyView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/06/2025.
//

import SwiftUI

struct FacultyView: View {
    
    @State var Faculty: String = ""
    @FocusState var keyboardFocused: Bool
    @State var isSelected: Bool = false
    @State var showAlert: Bool = false
    @Environment(ScoopViewModel.self) private var viewModel
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            titleView(text: "Your Faculty/Degree", count: 1)
                .padding(.top, 156)
                .padding(.bottom, 86)
            
            inputTextBox(placeholder: "Enter Faculty/Degree", inputtedText: $Faculty, textSize: 24, isFocused: $keyboardFocused)
            
            
            NextButton(isEnabled: checkFaculty(), onInvalidTap: {showAlert = true})
                .padding(.top, (84))
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            keyboardFocused = true
        }
    }
    func checkFaculty () -> Bool {
        
        if Faculty.count < 2 {
            return false
        } else {
            return true
        }
    }
}

#Preview {
    FacultyView()
        .environment(ScoopViewModel())
}
