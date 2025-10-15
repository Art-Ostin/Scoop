//
//  pDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI
import SwiftUIFlowLayout

struct ProfileDetailsView: View {
    @State var spacing: CGFloat = 36
    let screenWidth: CGFloat
    @State var p: UserProfile
    @State var responseLines = 3
    @State var event: UserEvent?
    

    
    
    
    
    var body: some View {
        
        
        TabView {
            VStack(spacing: spacing) {
                detailsSection1
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 36)
            
            VStack(spacing: spacing) {
                detailsSection2
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 16)
            
            VStack(spacing: spacing) {
                ScrollView {
                    vicesView

                    if (p.sex != "Male" || p.sex !=  "Female") {
                        Text(p.sex)
                    }
                    
                    if let thirdPrompt = p.prompt3 {
                        PromptView(prompt: thirdPrompt, spacing: spacing)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 16)
        }
        .tabViewStyle(.page)
        .frame(width: screenWidth - 8 - 32)
        .frame(maxHeight: .infinity, alignment: .top).ignoresSafeArea()
        .colorBackground(.background, top: true)
        .mask(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: Color.grayPlaceholder)
        .contentShape(Rectangle())
    }
}

extension ProfileDetailsView {
    
    
    @ViewBuilder
    private var detailsSection1: some View {
        keyInfo
        homeAndDegree
        movieAndSong
        divider
        
        if let event = event {
            
        }
        
        
        
        
        
        
        
        PromptView(prompt: p.prompt1, spacing: spacing)
            .onPreferenceChange(Text.LayoutKey.self) {layouts in
                responseLines = layouts.last?.layout.count ?? 0
            }
        declineButton
            .offset(y: responseLines == 4 ? -12 : 0)
    }

    @ViewBuilder
    private var detailsSection2: some View {
        Text("Interests")
            .font(.body(12, .bold))
            .foregroundStyle(Color.grayText)
            .frame(maxWidth: .infinity, alignment: .center)
        
        InterestsLayout(passions: p.interests, forProfile: true)
            .frame(maxWidth: .infinity)
        
        PromptView(prompt: p.prompt1, spacing: spacing)
    }
    
    private var sectionTitle: some View {
        Text("About")
            .font(.body(12))
            .foregroundStyle(Color(red: 0.39, green: 0.39, blue: 0.39))
    }
    
    private var keyInfo: some View {
        HStack (spacing: 0)  {
            InfoItem(image: "magnifyingglass", info: p.lookingFor)
            Spacer()
            InfoItem(image: "Year", info: p.year)
            Spacer()
            InfoItem(image: "Height", info: "193" + "cm")
        }
        .frame(maxWidth: .infinity)
    }
    
    private var homeAndDegree: some View {
        HStack(spacing: 0) {
            InfoItem(image: "House", info: p.hometown)
            Spacer()
            InfoItem(image: "ScholarStyle", info: p.degree)
        }
    }

    private var vicesView: some View {
        let interests: [(image: String, info: String)] = [
            ("AlcoholIcon", "Sometimes"), //p.drinking
            ("CigaretteIcon",  "Sometimes"), // p.smoking
            ("WeedIcon",     p.marijuana),
            ("DrugsIcon",    p.drugs)
        ]
        .filter { !$0.info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.info.lowercased() != "none" }

        return FlowLayout(mode: .vstack, items: interests, itemSpacing: 12) { item in
            InfoItem(image: item.image, info: item.info)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    
    private var movieAndSong: some View {
        HStack(spacing: 0) {
            InfoItem(image: "MovieIcon", info: p.favouriteMovie ?? "Fight Club")
            Spacer()
            HStack(alignment: .center, spacing: 16) {
                Image("MusicIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 17)
                VStack(alignment: .leading, spacing: 6) {
                    Text(p.favouriteSong ?? "Overmono")
                        .font(.body(17, .medium))
                    Text("Artist Name")
                        .font(.body(12, .regular))
                        .foregroundStyle(Color(red: 0.49, green: 0.49, blue: 0.49))
                }
            }
        }
    }
    
    private var divider: some View {
        RoundedRectangle(cornerRadius: 10)
        .foregroundColor(.clear)
        .frame(width: 225, height: 0.5)
        .background(Color(red: 0.75, green: 0.75, blue: 0.75))
    }
    private var declineButton: some View {
        Image("DeclineIcon")
            .frame(width: 45, height: 45)
            .stroke(100, lineWidth: 1, color: Color(red: 0.93, green: 0.93, blue: 0.93))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                
            }
    }
}

struct PromptView: View {
    let prompt: PromptResponse?
    let spacing: CGFloat
    var count: Int? { prompt?.response.count}
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: spacing - 8) {
            Text(prompt?.prompt ?? "No user Prompts")
                .font(.body(14, .italic))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(prompt?.response ?? "No user Response But we are going to simulate a longer response to see how the program responds and it is not responding very well")
                .font(.title(28))
                .lineLimit(4) // max response is 30 characters .lineLimit( count ?? 0 > 90 ? 4 : 3)
                .minimumScaleFactor(0.6)
                .lineSpacing(8)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
     }
}

struct InfoItem: View {
    
    let image: String
    let info: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(height: 17)
            
            Text(info)
                .font(.body(17, .medium))
            
        }
    }
}


/*
 .onPreferenceChange(Text.LayoutKey.self) {layouts in
     responseLines = layouts.last?.layout.count ?? 0

 */
