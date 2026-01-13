//
//  DetailsInfo.swift
//  Scoop
//
//  Created by Art Ostin on 02/11/2025.
//

import SwiftUI
import SwiftUIFlowLayout

struct UserKeyInfo: View {
    let p : UserProfile
    var body : some View {
        HStack(alignment: .center) {
                InfoItem(image: "Year", info: p.year)
                Spacer()
                InfoItem(image: "Height", info: ("193cm"))
                Spacer()
                InfoItem(image: "House", info: p.hometown)
            }
            Divider().background(Color.grayPlaceholder)
            InfoItem(image: "ScholarStyle", info: p.degree)
            Divider().background(Color.grayPlaceholder)
            InfoItem(image: "magnifyingglass", info: p.lookingFor)
    }
}
struct UserInterests: View {
    let p: UserProfile
    var body: some View {
        FlowLayout(mode: .vstack, items: p.interests, itemSpacing: 6) { text in
            Text(text)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .font(.body(14))
                .stroke(12, color: Color(red: 0.90, green: 0.90, blue: 0.90))
        }
        .padding(.horizontal, -6)
    }
}


struct UserExtraInfo: View {
    let p: UserProfile
    
    var vicesOnTwoLines: Bool {
        (p.favouriteSong == nil) && (p.favouriteMovie == nil)
    }
    var body: some View {
        
        if vicesOnTwoLines {
            VStack(spacing: 16) {
                HStack {
                    InfoItem(image: "AlcoholIcon", info: p.drinking)
                    Spacer()
                    InfoItem(image: "CigaretteIcon", info: p.smoking)
                }
                Divider().foregroundStyle(Color.grayPlaceholder)
                HStack {
                    InfoItem(image: "WeedIcon", info: p.marijuana)
                    Spacer()
                    InfoItem(image: "DrugsIcon",info: p.drugs)
                }
            }
        } else {
            VStack(alignment: .leading) {
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        InfoItem(image: "AlcoholIcon", info: p.drinking)
                        InfoItem(image: "CigaretteIcon", info: p.smoking)
                        InfoItem(image: "WeedIcon", info: p.marijuana)
                        InfoItem(image: "DrugsIcon",info: p.drugs)
                    }
                }
                Divider().foregroundStyle(Color.grayPlaceholder)
                HStack {
                    if let favouriteSong = p.favouriteSong {
                        InfoItem(image: "MusicIcon", info: favouriteSong)
                    } else if let favouriteMovie =  p.favouriteMovie {
                        InfoItem(image: "MovieIcon", info: favouriteMovie)
                    } else if let favouriteSong = p.favouriteSong, let favouriteMovie = p.favouriteMovie {
                        InfoItem(image: "MovieIcon", info: favouriteMovie)
                        Spacer()
                        InfoItem(image: "MusicIcon", info: favouriteSong)
                    }
                }
            }
        }
        Divider().foregroundStyle(Color.grayPlaceholder)
        InfoItem(image: "GenderIcon", info: p.sex)
    }
}


struct ProfileEvent: View {
    let p: UserProfile
    let event: UserEvent?
    
    var body: some View {
        if let event = event {
            EventFormatter(time: event.time, type: event.type, message: event.message, place: event.place, size: 24)
        } else if let idealMeet = p.idealMeetUp {
            EventFormatter(time: idealMeet.time, type: idealMeet.type, message: idealMeet.message, isInvite: true, place: idealMeet.place, size: 24)
        }
    }
}


    
