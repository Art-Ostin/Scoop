//
//  Frozen Screen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct FrozenScreen: View {
    
    let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
    @State var showWhyFrozen: Bool = false
    @State var tabSelection: Int = 0
    
    var body: some View {
        VStack(spacing: 72) {
            VStack(spacing: 12) {
                Text("Account Frozen Until")
                    .font(.body(17, .medium))
                
                Text(EventFormatting.expandedDate(twoWeeksFromNow))
                    .font(.custom("SFProRounded-Bold", size: 32))
            }
            
            
            Image("Monkey")

            VStack(spacing: 12) {
                Text("Account Frozen for Cancelling")
                    .font(.body(17, .italic))
                    .foregroundStyle(Color.grayText)
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)

                
                TabView(selection: $tabSelection) {
                    Tab(value: 0) {
                        BlockedContextView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    
                    Tab(value: 1) {
                        LargeClockView(targetTime: twoWeeksFromNow) {}
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .padding(.top, 96)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay (alignment: .topTrailing){
            TabInfoButton(showScreen: $showWhyFrozen)
        }
        .sheet(isPresented: $showWhyFrozen) {
            FrozenExplainedScreen()
        }
    }
}

#Preview {
    FrozenScreen()
}
