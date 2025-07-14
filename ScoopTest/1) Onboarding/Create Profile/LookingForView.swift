//
//  LookingForView.swift
//  ScoopTest
//
//  Created by Art Ostin on 20/06/2025.
//

import SwiftUI

struct LookingForView: View {
    
    @State private var options: [String] = ["🌳  Relationship", "🌀  Undecided"]
    
    @State private var options2: [String] = ["🍹  Something Casual"]
    
    @State var selectedIndex: Int? = nil
    
    var body: some View {
        VStack(){
            
            SignUpTitle(text: "Looking For", count: 4)
                .padding(.top, 32)
            
//            OptionView(options: options, width: 160, isFilled: false)
//                .padding(.top, 84)
//            
            HStack{
                Spacer()
//                OptionCell(options: options2, selectedIndex: $selectedIndex, width: 200, isFilled: false, index: 0)
                Spacer()
            }
            .padding(.top, 36)
        }
        
    }
}

#Preview {
    LookingForView()
        .padding(.horizontal, 32)
}
