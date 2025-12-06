//
//  DetailsInfo.swift
//  Scoop
//
//  Created by Art Ostin on 02/11/2025.
//

import SwiftUI

struct UserKeyInfo: View {
    let p : UserProfile
    var body : some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .customCaption()
                .frame(maxWidth: .infinity, alignment: .leading)
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
}

struct UserInterests: View {
    let p: UserProfile
    
    private var rows: [[String]] {
        p.interests.chunked(into: 3)
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interests")
                .customCaption()
            
            VStack(alignment: .leading, spacing: 30) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    let row = rows[rowIndex]
                    HStack(spacing: 18) {
                        ForEach(row.indices, id: \.self) { colIndex in
                            let interest = row[colIndex]
                            HStack(spacing: 18) {
                                Text(interest)
                                    .font(.body(16, .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                
                                if colIndex != row.count - 1 {
                                    NarrowDivide()
                                }
                            }
                        }
                    }
                }
            }
        }
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
                Text("Extra")
                    .customCaption()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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

struct PromptView: View {
    let prompt: PromptResponse
    var count: Int {prompt.response.count}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(prompt.prompt)
                .font(.body(14, .italic))
            
            Text(prompt.response)
                .font(.title(24, .bold))
                .lineSpacing(8)
                .font(.title(28))
                .lineLimit( count > 90 ? 4 : 3)
                .minimumScaleFactor(0.6)
                .lineSpacing(8)
        }
    }
}

struct ProfileEvent: View {
    
    let p: UserProfile
    let event: UserEvent?
    
    var body: some View {
        
        if let event = event {
            
            let hasMessage = event.message != nil
            
            VStack(alignment: .center, spacing: hasMessage ? 16 : 24) {
                Text("\(event.otherUserName)'s Invite")
                    .font(.body(14, .italic))
                    .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                EventFormatter(time: event.time, type: event.type, message: event.message, isInvite: true, place: event.place, size: 24)
                    .frame(maxWidth: .infinity, alignment: hasMessage ? .leading : .center)
            }
            .padding(.top, hasMessage ? -8 : 0)
            
        } else if let idealMeet =  p.idealMeetUp {
            VStack(alignment: .center, spacing: 24) {
                Text("\(p.name)'s Preferred Meet")
                    .font(.body(14, .italic))
                    .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                EventFormatter(time: idealMeet.time, type: idealMeet.type, message: idealMeet.message, isInvite: false, place: idealMeet.place, size: 24)
            }
        }
    }
}
