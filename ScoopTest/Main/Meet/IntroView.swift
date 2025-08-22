//
//  IntroView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 14/08/2025.
//

import SwiftUI

struct IntroView: View {
    
    @Bindable var vm: MeetViewModel
    let quote = quotes.shared.allQuotes.randomElement()!
    var body: some View {
        
        VStack(spacing: 72) {
            VStack(spacing: 36) {
                Text(quote.quoteText)
                    .font(.body(.italic))
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                
                Text("- \(quote.name)")
                    .font(.body(14, .bold))
            }
            ActionButton(text: "View Profiles") {
                Task { try? await vm.createWeeklyCycle() }
            }
        }
    }
}
