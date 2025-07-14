//
//  TabViewTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/06/2025.
//

import SwiftUI

struct LimitedAccessView: View {
    
    @State var selection: Int = 0
    
    
    var body: some View {
        
        
        
        TabView (selection: $selection) {
    
            Tab("", image: "LetterIcon", value: 0) {
                ZStack {
                    Color.background.ignoresSafeArea()
                    createProfilePage(
                        title: "Meet",
                        Screenimage: "CoolGuys",
                        description: "2 Profiles a Day. Send a Time & Place to Meet. No Texting.",
                        showProfile: false)
                    .toolbarBackground(Color.background, for: .tabBar)
                    .toolbarBackgroundVisibility(.visible, for: .tabBar)
                }
            }
            
            
            Tab("", image: "LogoIcon", value: 1) {
                ZStack {
                    Color.background.ignoresSafeArea(edges: .all)
                    createProfilePage(title: "Events", Screenimage: "EventCups", description: "Details for upcoming meet ups appear here", showProfile: false)
                        .toolbarBackground(Color.background, for: .tabBar)
                        .toolbarBackgroundVisibility(.visible, for: .tabBar)
                }
            }
            Tab("", image: "MessageIcon", value: 2) {
                ZStack {
                    Color.background.ignoresSafeArea(edges: .all)
                    createProfilePage(title: "Matches", Screenimage: "DancingCats", description: "View your previous matches here", showProfile: true)
                        .toolbarBackground(Color.background, for: .tabBar)
                        .toolbarBackgroundVisibility(.visible, for: .tabBar)
                }
            }
        }
    }
}

#Preview {
    LimitedAccessView()
        .environment(AppState())

}

struct createProfilePage: View {
    
//    @Environment(AppState.self) private var appState
    
    
    let title: String
    
    let Screenimage: String
    
    let description: String
    
    let showProfile: Bool
    
    var body: some View {
        
        VStack(spacing: 72){
            
            VStack(spacing: 48) {
                titleSection
                
                screenImage
            }
            
            descriptionText
            
//            ActionButton(text: "Create Profile") {
//                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)){
//                    appState.stage = .profileSetup(index: 0)
//                }
//            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 32)
    }
}

extension createProfilePage {
    
    private var titleSection: some View {
        Text(title)
            .font(.title())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 69)
    }
    
    private var screenImage: some View {
        Image(Screenimage)
            .resizable()
            .frame(width: 240, height: 240)
    }
    
    private var descriptionText: some View {
        Text(description)
            .frame(width: 281, height: 45)
            .font(.body(18, .medium))
            .lineLimit(2)
            .lineSpacing(7)
            .multilineTextAlignment(.center)
            
    }
    
    private var profileButton: some View {
        
        Button {
            
        } label: {
            Text ("Create profile")
                .frame(width: 179, height: 45)
                .background(Color.accent)
                .foregroundColor(.white)
                .font(.body(16, .bold))
                .cornerRadius(22.5)
                .shadow(color: .black.opacity (0.3), radius: 2, y: 2)
        }
    }
}
