//
//  MeetContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.
//

import SwiftUI

struct MeetContainerView: View {
    
    @State private var contentView: Int = 0
        var body: some View {
            
            ZStack(alignment: .bottom) {
                
                VStack{
                    title
                    
                    mainContent
                        .frame(maxWidth: .infinity)
                        .padding(.top, 36)
                }
                .padding(.horizontal, 36)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            Image("NightMode")
                .padding(.bottom, 60)
                .foregroundStyle(Color.gray)
            
            
            
        }
    }
#Preview {
    MeetContainerView()
}

extension MeetContainerView {
    
    private var title: some View {
        HStack{
            Text("Meet")
                .font(.custom("NewYorkLarge-Bold", size: 28))
            
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

    
    
    
    

    private var dailyProfilesButton: some View {
        ZStack{
            Button {
                contentView = 1
            } label: {
                HStack(alignment: .center, spacing: 10)
                {
                    Text("2 Daily Profiles")
                        .font(.custom("ModernEra-Bold", size: 18))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 14)
                        .background(Color.accent)
                        .cornerRadius(24)
                        .shadow( radius: 2, x: 0, y: 2)
                }
            }
        }
        .padding(.top, 96)
    }
    
    private var dailyProfilesSection: some View {
        
        VStack{
            quoteSection
            
            dailyProfilesButton
        }

    }
    
    private var mainContent: some View {
        
        VStack{
            if contentView == 0 {
                dailyProfilesSection
            } else {
                AnyView(Text("Hi"))
            }
        }
    }
}
