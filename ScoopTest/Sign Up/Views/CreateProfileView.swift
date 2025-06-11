//
//  TabViewTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/06/2025.
//

import SwiftUI

struct CreateProfileView: View {
    
    @State var selection: Int = 0
    
    
    var body: some View {
        TabView (selection: $selection) {
            
            Tab("", image: "letterIcon", value: 0) {
                createProfilePage(
                    title: "Meet",
                    Screenimage: "CoolGuys",
                    description: "2 Profiles a Day, send a Time & Place to Meet. No Texting.",
                    showProfile: false)
            }
            
            Tab("", image: "LogoIcon", value: 1) {
                createProfilePage(title: "Events", Screenimage: "Monkey", description: "If you match with someone and are meeting up, details will appear here.", showProfile: false)
            }
            
            Tab("", image: "MessageIcon", value: 2) {
                createProfilePage(title: "Matches", Screenimage: "DancingCats", description: "You can see all previous meet ups here", showProfile: true)
            }
        }
    }
}



#Preview {
    CreateProfileView()
        .environment(ScoopViewModel())
}




struct createProfilePage: View {
    
    @Environment(ScoopViewModel.self) private var viewModel

    
    let title: String
    
    let Screenimage: String
    
    let description: String
    
    let showProfile: Bool
    
    var body: some View {
            
            VStack{
                
                titleSection
                
                
                screenImage
                
                
                descriptionText
                
                profileButton
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 32)
    }
}

extension createProfilePage {
    
    private var titleSection: some View {
        Text(title)
            .font(.custom("NewYorkLarge-Bold", size: 24))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 69)
    }
    
    private var screenImage: some View {
        Image(Screenimage)
            .resizable()
            .frame(width: 240, height: 240)
            .padding(.top, 72)
            .padding(.bottom, 56)
    }
    
    private var descriptionText: some View {
        Text(description)
            .frame(width: 281, height: 39)
            .font(.custom("ModernEra-Medium", size: 16))
            .lineLimit(2)
            .lineSpacing(7)
            .multilineTextAlignment(.center)
            .padding(.bottom, 60)
    }
    
    
    private var profileButton: some View {
        
        Button {
            viewModel.stageIndex += 1
        } label: {
            Text ("Create profile")
                .frame(width: 179, height: 45)
                .background(Color.accent)
                .foregroundColor(.white)
                .font(.custom("ModernEra-Bold", size: 16))
                .cornerRadius(22.5)
                .shadow(color: .black.opacity (0.3), radius: 2, y: 2)
        }

        
        

    }
    
    
}
