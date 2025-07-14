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

    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            SignUpTitle(text: "Your Degree?", count: 1)
                .padding(.top, 136)
                .padding(.bottom, 60)
            
            InputTextfield(placeholder: "Enter Faculty/Degree", inputtedText: $Faculty, textSize: 24, isFocused: $keyboardFocused)
            
            
////            NextButton(
//                isEnabled: checkFaculty(),
//                onInvalidTap: {showAlert = true},
//            )
//                .padding(.top, (84))
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
        .environment(AppState())
}


