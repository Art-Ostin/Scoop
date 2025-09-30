//
//  profileDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

//    @Binding var vm: ProfileViewModel

import SwiftUI

struct ProfileDetailsView: View {
    
    @Binding var dragOffset: CGFloat
    
    @Binding var detailsOpen: Bool
    
    let detailsOpenYOffset: CGFloat
    
    let toggleDetailsThresh: CGFloat = -50
    
    @Binding var scrollImageBottomY: CGFloat
    
    var startingOffset: CGFloat {scrollImageBottomY + 36}
    
    
    var body: some View {
        
        VStack(spacing: 32) {

            Text("About")
                .font(.body(12))
                .foregroundStyle(Color(red: 0.39, green: 0.39, blue: 0.39))
            
            keyInfo
            
            homeAndDegree
            
            SoftDivider()
                .padding(.horizontal, 32)
            
            PromptView(prompt: PromptResponse(prompt: "What is the best date", response: "A girl who I never saw again.. in the same light"))
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.horizontal, 24)
        .stroke(30, lineWidth: 1, color: .grayPlaceholder)
        .background (
            RoundedRectangle(cornerRadius: 30)
                .fill(.white)
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
        )
        .padding(5)
    }
}

extension ProfileDetailsView {
    
    private var keyInfo: some View {
        HStack (spacing: 0)  {
            InfoItem(image: "magnifyingglass", info: "Casual")
            
            Spacer()
            
            InfoItem(image: "Year", info: "U3")
            
            Spacer()
            
            InfoItem(image: "Height", info: "193" + "cm")
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
    }
}


struct PromptView: View {
    
    let prompt: PromptResponse
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 24) {
            Text(prompt.prompt)
                .font(.body(14, .italic))
            
            Text(prompt.response)
                .font(.title(28))
                .lineSpacing(8)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, -1)
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


