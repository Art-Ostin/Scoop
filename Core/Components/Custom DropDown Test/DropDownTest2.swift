//
//  DropDownTest 1.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct DropDownTest_1: View {
    
    @State var vm: TimeAndPlaceViewModel = .init(text: "Testing")
    
    
    @State var showDropDown: Bool = false
    var body: some View {
        
        VStack {
            
            HStack {
                Text("Grab a drink")
                    .font(.body(16, .bold))
                Spacer()
                DropDownButton(isExpanded: $showDropDown)

            }
            
            SelectTimeView(vm: $vm)
            
        }
        
    }
}

#Preview {
    DropDownTest_1()
}
