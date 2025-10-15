//
//  pDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//


import SwiftUI

struct ProfileDetailsView: View {
    @State var spacing: CGFloat = 24
    let screenWidth: CGFloat
    let p: UserProfile
    
    var body: some View {
        VStack(spacing: spacing) {
            sectionTitle
            keyInfo
            homeAndDegree
            divider
            PromptView(prompt: p.prompt1, spacing: spacing)
                    .onPreferenceChange(Text.LayoutKey.self) {layouts in
                        let responseLines = layouts.last?.layout.count ?? 0
                        spacing = (responseLines >= 4) ? 24 : 32
                    }
            declineButton
        }
        .frame(width: screenWidth - 8 - 32)
        .colorBackground(.background, top: true)
        .mask(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: Color.grayPlaceholder)
        .contentShape(Rectangle())
    }
}

extension ProfileDetailsView {
    
    
    private var sectionTitle: some View {
        Text("About")
            .font(.body(12))
            .padding(.top, 12)
            .foregroundStyle(Color(red: 0.39, green: 0.39, blue: 0.39))
    }
    
    private var keyInfo: some View {
        HStack (spacing: 0)  {
            InfoItem(image: "magnifyingglass", info: p.lookingFor)
            Spacer()
            InfoItem(image: "Year", info: p.year)
            Spacer()
            InfoItem(image: "Height", info: p.height + "cm")
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
        HStack(spacing: 0) {
            InfoItem(image: "DrinkingIcon", info: p.drinking)
            Spacer()
            InfoItem(image: "SmokingIcon", info: p.smoking)
            Spacer()
            InfoItem(image: "WeedIcon", info: p.marijuana)
            Spacer()
            InfoItem(image: "DrugsIcon", info: p.drugs)
        }
        .frame(maxWidth: .infinity)
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
        
        VStack(alignment: .leading, spacing: spacing) {
            Text(prompt?.prompt ?? "No user Prompts")
                .font(.body(14, .italic))
            
            Text(prompt?.response ?? "No user Response")
                .font(.title(28))
                .lineLimit( count ?? 0 > 90 ? 4 : 3)
                .minimumScaleFactor(0.6)
                .lineSpacing(8)
                .multilineTextAlignment(.center)
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





