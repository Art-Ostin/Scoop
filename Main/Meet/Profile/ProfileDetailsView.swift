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
    @State var event: UserEvent?
    @State var noInitialPrompt = false
    
    @State var responseLines1 = 3
    @State var responseLines2 = 3

    let proxy: GeometryProxy
    var body: some View {
        
        TabView {
            VStack(spacing: spacing) {
                detailsSection1
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 36)
            
            VStack(spacing: 24) {
                detailsSection2
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 24)

            VStack(spacing: spacing) {
                vicesView
                extraInfo
                divider
                finalPagePrompt
                declineButton
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 24)
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
            EventFormatter(time: event.time, type: event.type, message: event.message, isInvite: true, place: event.place, size: 24)
                .onAppear {
                    print("No initial Prompt")
                    noInitialPrompt = true
                }
        } else if let idealMeet =  p.idealMeetUp {
            EventFormatter(time: idealMeet.time, type: idealMeet.type, message: idealMeet.message, isInvite: false, place: idealMeet.place, size: 24)
                .onAppear {
                    print ("This is the ideal Meet Up")
                    noInitialPrompt = true
                }
        } else {
            PromptView(prompt: p.prompt1)
                .onPreferenceChange(Text.LayoutKey.self) {layouts in
                    responseLines1 = layouts.last?.layout.count ?? 0
                }
        }
        declineButton
            .offset(y: responseLines1 == 4 ? -12 : 0)
    }

    @ViewBuilder
    private var detailsSection2: some View {
        
        VStack(spacing: 6) {
            Text("Interests")
                .font(.body(12, .bold))
                .foregroundStyle(Color.grayText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            InterestsLayout(passions: p.interests, forProfile: true)
                .frame(maxWidth: .infinity)

        }

        Group {
            if noInitialPrompt {
                PromptView(prompt: p.prompt1)
            } else {
                PromptView(prompt: p.prompt2)
                
            }
        }
        .onPreferenceChange(Text.LayoutKey.self) {layouts in
            responseLines2 = layouts.last?.layout.count ?? 0
        }
        declineButton
            .offset(y: responseLines2 == 4 ? -12 : 0)
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


    @ViewBuilder
    private var vicesView: some View {
        
        let sep = Text("          ")
        
        let line =
            Text(Image("AlcoholIcon")) + Text(p.drinking) + sep +
            Text(Image("CigaretteIcon")) + Text(p.smoking) + sep +
            Text(Image("WeedIcon")) + Text(p.marijuana) + sep +
            Text(Image("DrugsIcon")) + Text(p.drugs)

        line
            .font(.body(17, .medium))
    }
    
    
    @ViewBuilder
    private var extraInfo: some View {
        let specifySex: Bool = (p.sex != "man" || p.sex != "women")
        let specifyLanguages: Bool = !p.languages.isEmpty
        
        HStack {
            if specifyLanguages && specifySex {
                InfoItem(image: "GenderIcon", info: p.sex)
                Spacer()
                InfoItem(image: "Languages", info: p.languages)
            } else if specifyLanguages || specifySex {
                if specifyLanguages {
                    InfoItem(image: "Languages", info: p.languages)
                    Spacer()
                } else if specifySex {
                    InfoItem(image: "GenderIcon", info: p.sex)
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder private var finalPagePrompt: some View {
        VStack(spacing: 36) {
            if noInitialPrompt { PromptView(prompt: p.prompt2) }
            if p.prompt3 != nil { PromptView(prompt: p.prompt3) }
        }
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
    var count: Int? { prompt?.response.count}
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            Text(prompt?.prompt ?? "No user Prompts")
                .font(.body(14, .italic))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(prompt?.response ?? "")
                .font(.title(28))
                .lineLimit( count ?? 0 > 90 ? 4 : 3)
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
 Text(\(Image("AlcoholIcon")) + \(p.drinking))

 */



//        VStack(spacing: 12) {
//            HStack(spacing: 0) {
//                String(InfoItem(image: "AlcoholIcon", info: p.drinking))
//                Spacer()
//                InfoItem(image: "CigaretteIcon", info: p.smoking)
//            }
//            HStack(spacing: 0) {
//                InfoItem(image: "WeedIcon", info: p.marijuana)
//                Spacer()
//                InfoItem(image: "DrugsIcon", info: p.drugs)
//            }
//        }

/*
 @ViewBuilder
 private var vicesView: some View {
     
     let line =
         Text(Image("AlcoholIcon")) + Text(p.drinking) + "          " +
         Text(Image("CigaretteIcon")) + Text(p.smoking) + "          " +
         Text(Image("WeedIcon")) + Text(p.marijuana) + "          " +
         Text(Image("DrugsIcon")) + Text(p.drugs) + "          "

//        line
//            .font(.body)
//
//

 */
