//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//

import SwiftUI

struct EventView: View {
    
    @State var vm = EventViewModel()
    
    var body: some View {
        
        HStack(spacing: 32) {
        
            
            Clocksection(time: vm.hourRemaining, sign: "hr")
            
            Clocksection(time: vm.minuteRemaining, sign: "m")
            
            Clocksection(time: vm.secondRemaining, sign: "s")
            

        }
            .foregroundStyle(.white)
            .frame(width: 253, height: 52)
            .background(Color.accent)
            .cornerRadius(15)
        
    }
    
    func Clocksection(time: String, sign: String) -> some View {
        
        HStack (spacing: 5) {
            Text(time)
                .font(.custom("SFCompactRounded-Semibold", size: 28))
                Text(sign)
                    .font(.custom("SFCompactRounded-Regular", size: 14))
                    .offset(y: 5)
        }
    }
    
}

#Preview {
    EventView()
}
