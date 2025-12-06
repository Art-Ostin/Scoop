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
    let p: UserProfile
    let event: UserEvent?
    @State var noInitialPrompt = false
    var isThreePrompts: Bool { p.prompt3.response.isEmpty == true }
    @State var responseLines1 = 3
    @State var responseLines2 = 3
    @Binding var scrollSelection: Int?
    
    @State var scrollBottom: CGFloat = 0
    let scrollCoord = "Scroll"
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                part1DetailsView
                    .containerRelativeFrame(.horizontal)
                    .id(0)
                    .reportBottom(scrollCoord)
                part2DetailsView
                    .containerRelativeFrame(.horizontal)
                    .id(1)
                part1DetailsView
                    .containerRelativeFrame(.horizontal)
                    .id(2)
            }
            .scrollTargetLayout()
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .onPreferenceChange(ReportBottom.self) { scrollBottom = $0}
        .coordinateSpace(name: scrollCoord)
        .overlay(alignment: .top) {
            PageIndicator(count: 3, selection: scrollSelection ?? 0)
                .padding(.top, scrollBottom)
            DeclineButton() {}
                .padding(.top, scrollBottom - 23)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 24)
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollSelection, anchor: .center)
        .padding(.top, 16)
        .colorBackground(.background, top: true)
        .mask(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .stroke(30, lineWidth: 1, color: .grayPlaceholder)
    }
}

extension ProfileDetailsView {
    private var part1DetailsView: some View {
        VStack(spacing: 16) {
            DetailsSection(color: .accent) {
                UserKeyInfo(p: p)
            }
            DetailsSection() {
                PromptView(prompt: p.prompt1)
            }
        }
    }
    
    private var part2DetailsView: some View {
        VStack(spacing: 16) {
            DetailsSection(color: .accent) {
                UserInterests(p: p)
            }
            DetailsSection() {
                PromptView(prompt: p.prompt3)
            }
        }
    }
    
    
    
}
struct InfoItem: View {
    let image: String
    let info: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            //Overlay method, ensures all images take up same space
            Rectangle()
                .fill(Color.clear)
                .frame(width: 20, height: 17)
                .overlay {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                }
            
            Text(info)
                .font(.body(17, .medium))
        }
    }
}

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
    
    
    var vices: [(String, String)] { [
        ("AlcoholIcon", p.drinking),
        ("CigaretteIcon", p.smoking),
        ("WeedIcon", p.marijuana),
        ("DrugsIcon", p.drugs),]
    }
    
    var vicesOnTwoLines: Bool {
        (p.favouriteSong == nil) && (p.favouriteMovie == nil)
    }
        
    var body: some View {
        
        if vicesOnTwoLines {
            VStack {
                HStack {
                    InfoItem(image: "AlcoholIcon", info: p.drinking)
                    Spacer()
                    NarrowDivide()
                    Spacer()
                    InfoItem(image: "CigaretteIcon", info: p.smoking)
                }
                Divider().foregroundStyle(Color.grayPlaceholder)
                HStack {
                    InfoItem(image: "WeedIcon", info: p.marijuana)
                    Spacer()
                    NarrowDivide()
                    Spacer()
                    InfoItem(image: "DrugsIcon",info: p.drugs)
                }
            }
        } else {
            VStack {
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
                    if
                }
            }
            
            
            //Have them all on one line
            // Have movies on next line
        }
        
        Divider().foregroundStyle(Color.grayPlaceholder)
        
        InfoItem(image: "GenderIcon", info: p.sex)
        
        
    }
}





struct NarrowDivide: View {
    var body: some View {
        Rectangle()
            .foregroundColor(.clear)
            .frame(width: 0.7, height: 16)
            .background(Color(red: 0.9, green: 0.9, blue: 0.9))
    }
}


extension ProfileDetailsView {
    @ViewBuilder
    private var detailsSection1: some View {
        keyInfo
        homeAndDegree
        
        VStack(spacing: 24) {
            
            VStack (spacing: 16) {
                movieAndSong
                divider
            }
            
            if let event = event {
                
                let hasMessage = event.message != nil
                
                VStack(alignment: .center, spacing: hasMessage ? 16 : 24) {
                    Text("\(event.otherUserName)'s Invite")
                        .font(.body(14, .italic))
                        .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    EventFormatter(time: event.time, type: event.type, message: event.message, isInvite: true, place: event.place, size: 24)
                        .onAppear {
                            print("No initial Prompt")
                            noInitialPrompt = true
                        }
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
                        .onAppear {
                            print ("This is the ideal Meet Up")
                            noInitialPrompt = true
                        }
                }
            } else {
                PromptView(prompt: p.prompt1)
                    .onPreferenceChange(Text.LayoutKey.self) {layouts in
                        responseLines1 = layouts.last?.layout.count ?? 0
                    }
            }
        }
    }
    
    @ViewBuilder
    private var detailsSection2: some View {
        
        let options = p.interests
        
        VStack(spacing: 12) {
            Text("Interests")
                .font(.body(12, .bold))
                .foregroundStyle(Color.grayText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(x: 3)
            
            FlowLayout(mode: .scrollable, items: options, itemSpacing: 6) { input in
                OptionCellProfile(text: input)
            }
            .padding(.horizontal, -5)
        }
        
        divider
        
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
    }
    
    @ViewBuilder
    private var detailsSection3: some View {
        extraInformation
        divider
        finalPagePrompt
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
    private var extraInformation: some View {
        
        let options: [InfoItemStruct] = {
            var a: [InfoItemStruct] = [
                .init(image: "AlcoholIcon",  info: p.drinking),
                .init(image: "CigaretteIcon", info: p.smoking),
                .init(image: "WeedIcon",      info: p.marijuana),
                .init(image: "DrugsIcon",     info: p.drugs),
                .init(image: "GenderIcon",    info: p.sex)
            ]
            
            if !p.languages.isEmpty {
                a.append(.init(image: "Languages", info: p.languages))
            }
            return a
        }()
        
        VStack(spacing: 12) {
            Text("Extra")
                .font(.body(12, .bold))
                .foregroundStyle(Color.grayText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(x: 3)
            
            FlowLayout(mode: .scrollable, items: options, itemSpacing: 6) { input in
                OptionCellProfile2(infoItem: input)
            }
            .padding(.horizontal, -5)
        }
    }
    
    
    @ViewBuilder
    private var extraInfo: some View {
        let specifySex: Bool = (p.sex != "man" && p.sex != "women")
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
            if noInitialPrompt {
                PromptView(prompt: p.prompt2)
            } else if isThreePrompts {
                PromptView(prompt: p.prompt3)
            }
        }
    }
    
    
    private var movieAndSong: some View {
        HStack(alignment: .top, spacing: 0) {
            InfoItem(image: "MovieIcon", info: p.favouriteMovie ?? "Fight Club")
            Spacer()
            
            HStack(alignment: .top, spacing: 16) {
                Image("MusicIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 17)
                    .offset(y: 1)
                
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
}





struct InfoItemStruct {
    let image: String
    let info: String
}


struct OptionCellProfile: View {
    
    let text: String
    
    var body: some View {
        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .font(.body(14))
            .foregroundStyle(Color.black)
            .background (
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 1)
                    )
            )
    }
}


struct OptionCellProfile2: View {
    
    let infoItem: InfoItemStruct
    var body: some View {
        HStack(spacing: 16) {
            Image(infoItem.image)
                .resizable()
                .scaledToFit()
                .frame(height: 17)
            
            Text(infoItem.info)
                .font(.body(14))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .foregroundStyle(Color.black)
        .background (
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 1)
                )
        )
    }
}





/*
 @ViewBuilder
 private var part2Details: some View {
 VStack(spacing: 32) {
 DetailsInfo(title: "Passions") {
 ForEach(p.interests.indices, id: \.self) { index in
 HStack {
 InfoItem(image: "HappyFace", info: p.interests[index])
 
 verticalDivider
 }
 }
 }
 }
 }
 
 
 @ViewBuilder
 private var part1DetailsView: some View {
 
 VStack(spacing: 32) {
 DetailsInfo(title: "About") {
 detailsLine(
 InfoItem(image: "magnifyingglass", info: p.lookingFor),
 InfoItem(image: "Year", info: p.year))
 Divider()
 detailsLine(
 InfoItem(image: "ScholarStyle", info: p.degree),
 InfoItem(image: "Height", info: "193" + "cm"))
 Divider()
 detailsLine(
 InfoItem(image: "House", info: p.hometown),
 InfoItem(image: "HappyFace", info: p.interests.first ?? ""))
 }
 PromptView(prompt: p.prompt1, spacing: 32)
 }
 .padding(.horizontal, 24)
 }
 */


/*
 
 TabView {
 VStack(spacing: spacing) {
 detailsSection1
 Text("Hello World")
 }
 .padding(.top, 36)
 .frame(maxHeight: .infinity, alignment: .top)
 
 VStack(spacing: 24) {
 detailsSection2
 }
 .padding(.top, 24)
 .frame(maxHeight: .infinity, alignment: .top)
 
 VStack(spacing: 24) {
 detailsSection3
 }
 .padding(.top, 24)
 .frame(maxHeight: .infinity, alignment: .top)
 
 if noInitialPrompt && isThreePrompts {
 VStack(spacing: 72) {
 PromptView(prompt: p.prompt3)
 declineButton
 }
 .padding(.top, 36)
 .frame(maxHeight: .infinity, alignment: .top)
 }
 
 */

/*
 
 VStack(spacing: 12) {
 Text("About")
 .font(.body(13, .italic))
 .foregroundStyle(Color.grayText)
 .frame(maxWidth: .infinity, alignment: .leading)
 
 
 
 VStack (spacing: 10) {
 HStack {
 InfoItem(image: "magnifyingglass", info: p.lookingFor)
 Spacer()
 verticalDivider
 Spacer()
 InfoItem(image: "Year", info: p.year)
 }
 
 horizontalDivider
 
 HStack {
 InfoItem(image: "ScholarStyle", info: p.degree)
 Spacer()
 verticalDivider
 Spacer()
 InfoItem(image: "Height", info: "193" + "cm")
 }
 
 horizontalDivider
 
 HStack {
 InfoItem(image: "House", info: p.hometown)
 Spacer()
 verticalDivider
 Spacer()
 InfoItem(image: "HappyFace", info: p.interests.first ?? "")
 }
 }
 .padding(18)
 .frame(maxWidth: .infinity)
 .stroke(12, lineWidth: 1, color: .grayPlaceholder)
 }
 */

/*
 struct PromptView: View {
 
 let prompt: PromptResponse?
 var count: Int? { prompt?.response.count}
 
 let spacing: CGFloat
 
 init(prompt: PromptResponse?, spacing: CGFloat = 16) {
 self.prompt = prompt
 self.spacing = spacing
 }
 
 var body: some View {
 
 VStack(alignment: .leading, spacing: spacing) {
 Text(prompt?.prompt ?? "No user Prompts")
 .font(.body(14, .italic))
 .frame(maxWidth: .infinity, alignment: .leading)
 
 Text(prompt?.response ?? "")
 .font(.title(28))
 .lineLimit( count ?? 0 > 90 ? 4 : 3)
 .minimumScaleFactor(0.6)
 .lineSpacing(8)
 .multilineTextAlignment(.center)
 .frame(maxWidth: .infinity, alignment: .top)
 .padding(.top, -12)
 }
 .frame(maxWidth: .infinity)
 }
 }
 
 
 private var verticalDivider: some View {
 Rectangle()
 .foregroundStyle(Color(red: 0.70, green: 0.70, blue: 0.70))
 .frame(width: 0.5, height: 25)
 }
 
 private var horizontalDivider: some View {
 Rectangle()
 .foregroundStyle(Color.grayPlaceholder)
 .containerRelativeFrame(.horizontal)
 .frame(height: 1)
 }
 
 func detailsLine (_ item1: InfoItem, _ item2: InfoItem) -> some View {
 HStack {
 item1
 Spacer()
 verticalDivider
 Spacer()
 item2
 }
 }
 
 */


extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { start in
            Array(self[start..<Swift.min(start + size, count)])
        }
    }
}

/*
 var vices: [(String, String)] { [
     ("AlcoholIcon", p.drinking),
     ("CigaretteIcon", p.smoking),
     ("WeedIcon", p.marijuana),
     ("DrugsIcon", p.drugs),]
 }
 */
