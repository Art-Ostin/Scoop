//
//  InviteTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTimeRow: View {
    
    @Bindable var vm: TimeAndPlaceViewModel
    
    var body: some View {
        let time = vm.event.time
        
        HStack {
            if time != nil { Text(formatTime(date: time)).font(.body(18))
            } else {Text("Time").font(.body(20, .bold))}
            
            Spacer()
            
            DropDownButton(isExpanded: $vm.showTimePopup)
        }
    }
}


//
//#Preview {
//    InviteTimeRow()
//}
