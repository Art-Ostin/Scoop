//
//  MeetContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.
//

import SwiftUI

struct MeetContainer: View {
    
    @State private var contentView: Int = 0
        var body: some View {
            NavigationStack{
                ZStack(alignment: .bottom) {
                    VStack{
                        title
                            .padding(.horizontal, 36)

                        mainContent
                            .frame(maxWidth: .infinity)
                            .padding(.top, 36)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .navigationTitle(Text(""))
                
                Image("NightMode")
                    .padding(.bottom, 48)
                    .foregroundStyle(Color.gray)
            }
            
        }
    }

#Preview {
    MeetContainer()
        .offWhite()
}


extension MeetContainer {
    
    private var title: some View {
        HStack{
            Text("Meet")
                .font(.custom("NewYorkLarge-Bold", size: 36))
            
            Spacer()
            Image(systemName: "magnifyingglass")
                .resizable()
                .frame(width: 20, height: 20)
        }
        .padding(.top, 72)
    }
    
    private var quoteSection: some View {
        let quote = quotes.shared.allQuotes.randomElement() ?? quoteContent(quoteText: "Bug error 132, please report", name: "System")
        return ZStack {
            VStack(spacing: 36) {
                    Text(quote.quoteText)
                        .font(.custom("ModernEra-MediumItalic", size: 16))
                        .kerning(0.5)
                        .lineSpacing(10)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .center)

                Text("- \(quote.name)")
                        .font(.custom("ModernEra-Bold", size: 14))
                }
            }
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .padding(.top, 72)
        }
    
    private var dailyProfilesSection: some View {
        
        VStack{
            quoteSection
            
            ActionButton(text: "2 Daily Profiles") {
                contentView = 1
            }
            .padding(.top, 96)
        }
    }
    
    private var mainContent: some View {
        
        VStack{
            if contentView == 0 {
                dailyProfilesSection
            } else if contentView == 1 {
                TwoDailyProfilesView()
            }
            else {
                AnyView(Text("Hello There"))
            }
        }
    }
}
