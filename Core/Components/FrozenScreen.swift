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
            VStack(spacing: 72) {
                VStack(spacing: 24) {
                    Text("Account Frozen Until")
                        .font(.body(20, .medium))
                    
                    Text(EventFormatting.expandedDate(twoWeeksFromNow))
                        .font(.custom("SFProRounded-Bold", size: 32))
                }
                Image("Monkey")

                LargeClockView(targetTime: twoWeeksFromNow, isButton: true) {}
            }
        }
        .padding(.top, 96)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        
    }
}

#Preview {
    Frozen_Screen()
}
