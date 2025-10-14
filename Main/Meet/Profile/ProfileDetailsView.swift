//
//  profileDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//


import SwiftUI

struct ProfileDetailsView: View {
    
    @State var vSpacing: CGFloat = 0
    
    
    
    var smallvSpacing: Bool { vSpacing <= 24 }
    
    @State private var initialDetailsWidth: CGFloat?
    
    let response = "The Organizational Development Journal (Summer 2006) reported on and just"
    let prompt = "What's the best date"
    
    var body: some View {
        
        VStack(spacing: 48) {
            VStack(spacing: vSpacing) {
                sectionTitle
                keyInfo
                homeAndDegree
            }
            
            VStack(spacing: 24) {
                PromptView(prompt: PromptResponse(prompt: prompt, response: response), vSpacing: (vSpacing * 2/3), count: response.count)
                    .onPreferenceChange(Text.LayoutKey.self) {layouts in
                        let responseLines = layouts.last?.layout.count ?? 0
                        vSpacing = (responseLines >= 4) ? 24 : 32
                    }
                declineButton
            }

        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: DetailsWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(DetailsWidthKey.self) { w in
            if initialDetailsWidth == nil { initialDetailsWidth = w }
        }
        .frame(width: initialDetailsWidth.map { $0 - 32 })
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
            InfoItem(image: "magnifyingglass", info: "Casual")
                .frame(maxWidth: .infinity, alignment: .leading)
            InfoItem(image: "Year", info: "U3")
                .frame(maxWidth: .infinity, alignment: .center)
            InfoItem(image: "Height", info: "193" + "cm")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    
    private var homeAndDegree: some View {
        
        HStack(spacing: 0) {

            InfoItem(image: "House", info: "London")
            
            Spacer()
            
            InfoItem(image: "ScholarStyle", info: "Politics")
        }
    }

    private var vicesView: some View {
        HStack(spacing: 0) {
            InfoItem(image: "DrinkingIcon", info: "Yes")
            Spacer()
            InfoItem(image: "SmokingIcon", info: "Yes")
            Spacer()
            InfoItem(image: "WeedIcon", info: "Yes")
            Spacer()
            InfoItem(image: "DrugsIcon", info: "Yes")
        }
        .frame(maxWidth: .infinity)
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
    
    let prompt: PromptResponse
    let vSpacing: CGFloat
    let count: Int
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: vSpacing) {
            Text(prompt.prompt)
                .font(.body(14, .italic))
            
            Text(prompt.response)
                .font(.title(28))
                .lineLimit( count > 90 ? 4 : 3)
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

private struct DetailsWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
