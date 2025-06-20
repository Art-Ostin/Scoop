//
//  TwoDailyProfilesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/06/2025.
//

import SwiftUI

struct TwoDailyProfilesView: View {
    @State private var selection: Int = 0
    
    @State private var name1 = "Jamie"
    @State private var name2 = "John"
    @State private var Image1 = "ProfileMockA"
    @State private var Image2 = "ProfileMockB"
    
    @State private var showProfile1: Bool = false
    @State private var showProfile2: Bool = false
    
    
    
    var body: some View {
        
        ZStack {
            
            VStack{
                heading
                
                underlinedLine
                
                twoDailyProfiles
            }
        }
        .fullScreenCover(isPresented: $showProfile1) {
            ProfileView()
        }
        .fullScreenCover(isPresented: $showProfile2) {
            ProfileView()
        }
    }
}
#Preview {
    TwoDailyProfilesView()
        .offWhite()

}

extension TwoDailyProfilesView {
    
    private var heading: some View {
        HStack{
            Text(name1)
                .font(.custom(selection == 0 ? "NewYorkLarge-Bold" : "NewYorkMedium-Medium", size: 16))
                .foregroundStyle(selection == 0 ? Color.accent : Color.black)
            Spacer()
            Text(name2)
                .font(.custom(selection == 1 ? "NewYorkLarge-Bold" : "NewYorkMedium-Medium", size: 16))
                .foregroundStyle(selection == 1 ? Color.accent : Color.black)
        }
        .padding(.horizontal, 36)
    }
    
    private var underlinedLine: some View {
        HStack {
            if selection == 1 {
                Spacer()
            }
            Rectangle()
                .frame(width: selection == 0 ? 60 : 50, height: 1.3)
                .foregroundStyle(Color.accentColor)
            if selection == 0 {
                Spacer()
            }
        }
        .padding(.horizontal, 30)
    }
    
    
    private var twoDailyProfiles: some View {
        
        TabView(selection: $selection) {
            Image(Image1)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    showProfile1.toggle()
                }
                .tag (0)
            
            Image(Image2)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    showProfile2.toggle()
                }
                .tag (1)
        }
        .tabViewStyle(PageTabViewStyle())
        .padding(.top, 16)
        .indexViewStyle(.page(backgroundDisplayMode: .never))
    }
}
