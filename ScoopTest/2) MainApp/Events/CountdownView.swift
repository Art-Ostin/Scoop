//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//

import SwiftUI
import Combine

struct CountdownView: View {
    
    @State var vm = CountdownViewModel()
    
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
            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
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
    CountdownView()
}
