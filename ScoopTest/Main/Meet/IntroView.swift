//
//  IntroView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

import SwiftUI

struct IntroView2: View {
    
    @Binding var vm: MeetUpViewModel2
    @Binding var showProfiles: Bool
    
    let quote = quotes.shared.allQuotes.randomElement()!
    
    var body: some View {

        VStack (spacing: 156) {
                quoteSection
            ActionButton(text: "2 Daily Profiles", onTap: {
                Task { await vm.updateTwoDailyProfiles() }
                showProfiles = true
                vm.dep.defaultsManager.setDailyProfileTimer()
            })
            }
            .padding(.horizontal, 32)
            .frame(maxHeight: .infinity, alignment: .top)
            .overlay(
                Image("NightImages")
                    .padding(.bottom, 84)
                    .allowsHitTesting(false),
                alignment: .bottom
            )
    }
}

extension IntroView2 {
    
    private var quoteSection: some View {
        VStack(spacing: 36) {
            Text(quote.quoteText)
                .font(.body(.italic))
                .lineSpacing(8)
                .multilineTextAlignment(.center)
            
            Text("- \(quote.name)")
                .font(.body(14, .bold))
        }
    }
}
