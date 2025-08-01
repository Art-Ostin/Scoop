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
    
    let profile1: UserProfile
    let profile2: UserProfile
    
    var body: some View {
        
        VStack(spacing: 36) {
            title
            heading
            TabView {
                Group { profileImageTab(url: profile1.imagePathURL?.first.flatMap(URL.init(string:)))}.tag(0)
                Group { profileImageTab(url: profile2.imagePathURL?.first.flatMap(URL.init(string:)))}.tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            
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


//#Preview {
//    TwoDailyProfilesView(state: .constant(.twoDailyProfiles))
//}

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
                Text(profile1.name ?? "")
                    .font(.title(16, selection == 0 ? .bold : .medium))
                    .foregroundStyle(selection == 0 ? Color.accent : Color.black)
                
                Spacer()
                
                Text(profile2.name ?? "")
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
    
    
    @ViewBuilder private func profileImageTab(url: URL?) -> some View {
        if let url = url {
            CachedAsyncImage(url: url) { Image in
                Image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 320, height: 422)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
            } placeholder: {
                ProgressView()
            }
        }
    }

    
//    
//    @ViewBuilder private var twoDailyProfiles: some View {
//        
//        TabView(selection: $selection) {
//            Group {
//                if let url1 = profile1.imagePathURL?.first.flatMap(URL.init(string:)) {
//                    CachedAsyncImage(url: url1) { Image in
//                        Image
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 320, height: 422)
//                            .clipped()
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
//                    } placeholder: {
//                        ProgressView()
//                    }
//                }
//            }
//            .tag(0)
//            
//            Group {
//                if let url2 = profile2.imagePathURL?.first.flatMap(URL.init(string:)) {
//                    CachedAsyncImage(url: url2) { Image in
//                        Image
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 320, height: 422)
//                            .clipped()
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
//
//                    } placeholder: {
//                        ProgressView()
//                    }
//                }
//            }
//            .tag (1)
//        }
//        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//    }
}


