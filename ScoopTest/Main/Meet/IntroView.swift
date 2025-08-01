//
//  IntroView.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/06/2025.
//

import SwiftUI

struct IntroView: View {
    
    @Binding var vm: MeetUpViewModel?
    
    let quote = quotes.shared.allQuotes.randomElement()!
    
    var body: some View {

        VStack (spacing: 156) {
                title
                quoteSection
                ActionButton(text: "2 Daily Profiles", onTap: {vm?.state = .twoDailyProfiles})
            }
            .padding(.horizontal, 32)
            .frame(maxHeight: .infinity, alignment: .top)
            .overlay(
                Image("NightImages")
                    .padding(.bottom, 84),
                alignment: .bottom
                )
    }
}

//#Preview {
//    IntroView(state: .constant(.intro))
//}

extension IntroView {
    
    private var title: some View {
        HStack{
            Text("Meet")
                .font(.title())
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .resizable()
                .frame(width: 20, height: 20)
        }
        .padding(.top, 48)
    }
    
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
