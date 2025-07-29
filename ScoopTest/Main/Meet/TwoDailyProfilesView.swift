//
//  TwoDailyProfilesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/06/2025.
//

import SwiftUI

struct TwoDailyProfilesView: View {
    
    @State private var selection: Int = 0
    @Binding var state: MeetSections?
    @State private var name1 = "Adam"
    @State private var name2 = "John"
    @State private var Image1 = "ProfileMockA"
    @State private var Image2 = "ProfileMockB"
    
    
    var body: some View {
        
        VStack(spacing: 36) {
            title
            heading
            twoDailyProfiles
        }
        .padding(.horizontal, 32)
        .frame(maxHeight: .infinity, alignment: .top)
        .overlay(
            Image("NightImages")
                .padding(.bottom, 72),
            alignment: .bottom
            )
    }
}


#Preview {
    TwoDailyProfilesView(state: .constant(.twoDailyProfiles))
}

extension TwoDailyProfilesView {
    
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
    
    
    
    private var heading: some View {
        
        VStack (spacing: 6){
            
            // The Two Names
            HStack{
                Text(name1)
                    .font(.title(16, selection == 0 ? .bold : .medium))
                    .foregroundStyle(selection == 0 ? Color.accent : Color.black)
                
                Spacer()
                
                Text(name2)
                    .font(.title(16, selection == 1 ? .bold : .medium))
                    .foregroundStyle(selection == 1 ? Color.accent : Color.black)
            }
            .padding(.horizontal, 2)
            
            // The Underline Section
            HStack {
                if selection == 1 {
                    Spacer()
                }
                Rectangle()
                    .frame(width: selection == 0 ? 53 : 43, height: 1.6)
                    .foregroundStyle(Color.accentColor)
                if selection == 0 {
                    Spacer()
                }
            }
        }
    }
    
    
    private var twoDailyProfiles: some View {
        
        TabView(selection: $selection) {
                Image(Image1)
                    .ignoresSafeArea(.all)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .tag (0)
                    .onTapGesture {
                        state = .profile
                    }

                Image(Image2)
                    .ignoresSafeArea(.all)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .tag (1)
                    .onTapGesture {
                        state = .profile
                    }
            
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}
