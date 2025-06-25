//
//  MeetContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.
//


enum MeetSections {
    case intro
    case twoDailyProfiles
    case profile
}


import SwiftUI

struct MeetContainer: View {
    
    @State private var state = MeetSections.twoDailyProfiles
    
    var body: some View {
        
        switch state {
            
        case .intro:
            IntroView(state: $state)
            
        case .twoDailyProfiles:
            TwoDailyProfilesView(state: $state)
            
        case .profile:
            ProfileView(state: $state, )
        }
        
    }
}

#Preview {
    MeetContainer()
        .environment(AppState())
        .offWhite()
}



//
//extension MeetContainer {
//    
//    private var title: some View {
//        
//        HStack{
//            Text("Meet")
//                .font(.title())
//            Spacer()
//            
//            Image(systemName: "magnifyingglass")
//                .resizable()
//                .frame(width: 20, height: 20)
//        }
//        .padding(.top, 72)
//    }
//    
//    private var quoteSection: some View {
//        
//        return VStack (spacing: 132) {
//            //Quote Section
//            VStack(spacing: 36) {
//                Text(quote.quoteText)
//                    .font(.body(.italic))
//                    .lineSpacing(8)
//                    .multilineTextAlignment(.center)
//                
//                Text("- \(quote.name)")
//                    .font(.body(14, .bold))
//            }
//            
//            ActionButton(text: "2 Daily Profiles", onTap: {contentView += 1})
//        }
//        .padding(.top, 132)
//    }
//
//}
//    
//    
  



//


//    private var dailyProfilesSection: some View {
//        
//        VStack{
//            quoteSection
//            
//            ActionButton(text: "2 Daily Profiles") {
//                contentView = 1
//            }
//            .padding(.top, 96)
//        }
//    }
//    
//    private var mainContent: some View {
//        
//        VStack{
//            if contentView == 0 {
//                dailyProfilesSection
//            } else if contentView == 1 {
//                TwoDailyProfilesView()
//            }
//            else {
//                AnyView(Text("Hello There"))
//            }
//        }
//    }
//}

