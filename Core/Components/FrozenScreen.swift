//
//  Frozen Screen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct Frozen_Screen: View {
    
    let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
    
    
    var body: some View {
        ZStack(alignment: .top){
            
            

            VStack {
                Text("Account Frozen For")
                    .font(.body(24, .bold))
                
                LargeClockView(targetTime: twoWeeksFromNow, isButton: false) {
                    
                }
            }
            
            
//            Text("🥶")
//                .font(.body(100))
            
        }
        .padding(.top, 96)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            Color(red: 0, green: 0.65, blue: 0.73)
                .opacity(0.95)
        )
        .allowsHitTesting(false)
    }
}

#Preview {
    Frozen_Screen()
}
