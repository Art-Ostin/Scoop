//
//  Passions.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/06/2025.
//

import SwiftUI
import SwiftUIFlowLayout

struct PassionsView: View {
    
    //Store all the selected passions here. Have "custom Text" to store selectedPassions, which are typed (As have different display)
    @State private var selectedPassions: [String] = []
    @State var customText: [String] = []

    
    // Different selectedIndex for each different Passion category
    @State var socialPassionsSelectedIndex: Int? = nil
    @State var interestsSelectedIndex: Int? = nil
    @State var activitiesSelectedIndex: Int? = nil
    @State var sportsPassionsSelectedIndex: Int? = nil
    @State var music1SelectedIndex: Int? = nil
    @State var music2SelectedIndex: Int? = nil
    @State var music3SelectedIndex: Int? = nil
    
    
    // Which Tab is chosen and the variable to store the text and show keyboard
    @State private var selectedTabIndex: Int = 0
    @State var textFieldText: String = ""
    @FocusState private var isFocused: Bool
    
    
    //All The Different defualt Options
    @State private var socialPassions: [String] = [ "Bars", "Raves", "Clubbing", "Movie Nights", "House Party", "Darties", "Dinner Parties", "Road Trips", "Concerts", "Wine n Dine", "Pub", "Game Nights", "Brunch", "Festival", "Karoke"]
    @State private var interests: [String] = [ "Reading", "Poetry","Cold Water Swimming", "Sport","Writing", "Photography", "Museums", "Psychology", "Anime", "Nature", "Fashion", "Astronomy", "Movies", "Entrepreneurship", "Philosophy", "Formula 1", "Volunteering", "Politics", "Art", "Podcasts", "Food", "Music"]
    @State private var activities = ["Camping", "Hiking", "Backpacking", "Beach", "Road Trips", "Thrifting", "Cooking", "Chess", "Board Games", "Table Tennis", "Socialising", "Gaming", "Acting", "Drawing", "Painting", "Djing", "Meditation", "Partying"]
    @State private var sportsPassions = ["Badminton", "Rugby", "Baseball", "Soccer", "Basketball", "Tennis", "Football", "Handball", "Lacrosse", "Volleyball", "Softball", "Boxing", "Athletics", "Cycling", "Running", "Rowing", "Gym/Fitness", "Martial Arts", "Skateboarding", "Ice Hockey", "Pilates", "Yoga", "Kayaking", "Roller Skating", "Climbing", "Ultimate Frisbee", "Ice Skating", "Snowboarding", "Darts", "Golf", "Mountain Biking", "Bouldering", "Quidditch", "Surfing", "Skiing", "Sailing", "Spikeball", "Shooting", "Squash", "Fencing"]
    @State private var music1 = ["Pop", "Rock", "Hip-Hop", "Grime", "R & B", "Country", "Reggae", "Soul", "Jazz", "Funk", "Blues", "Acoustic", "Folk", "Latin Pop", "Disco", "K-Pop", "Afrobeat", "Metal", "Classical", "Chill", "Retro Bangers"]
    @State private var music2 = ["EDM", "House", "Techno", "Trance", "D & B", "Dance", "Dubstep", "Electronica", "Ambient", "Tech House", "Melodic Techno", "Psytrance", "Big Room", "Acid", "Garage", "Afro tech", "Tropical House", "Jungle", "Liquid"]
    @State private var music3 = ["Indie", "Indie pop", "Indie Rock", "Lo-fi", "Shoegaze", "Dream Pop", "Psychedelic Rock", "Grunge", "Emo", "Post-Rock", "Slowcore", "Folk Music", "Experimental", "Punk"]
    
    
    var body: some View {
        
        VStack{
            titleSection

            menuScroll

            tabView
                .padding(.horizontal, -5)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 32)
        .onChange(of: selectedTabIndex) { oldValue, newValue in
            isFocused = (newValue == 1)
        }
    }
}


#Preview {
    PassionsView()
        .environment(AppState())
        .offWhite()
}

extension PassionsView {
    
    private var titleSection: some View {
        SignUpTitle(text: "Passions", count: 3, subtitle: "\(selectedPassions.count)/5")
            .padding(.top, 60)
            .padding(.bottom, 60)
    }
    
    private var menuScroll: some View {
        VStack (spacing: 17) {
            HStack {
                Text("Explore")
                    .foregroundStyle( selectedTabIndex == 0 ? .accent : Color(red: 0.3, green: 0.3, blue: 0.3) )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.1)){
                            selectedTabIndex = 0
                        }
                    }
                Spacer()
                Text("Custom")
                    .foregroundStyle( selectedTabIndex == 1 ? .accent : Color(red: 0.3, green: 0.3, blue: 0.3) )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.1)){
                            selectedTabIndex = 1
                        }
                    }
            }
            .padding(.horizontal, 5)
            .font(.body(16, .bold))
            
            
            
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 332, height: 1, alignment: .center)
                    .foregroundStyle(Color(red: 0.86, green: 0.86, blue: 0.86))
                
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 67, height: 1)
                    .frame(maxWidth: .infinity, alignment: selectedTabIndex == 0 ? .leading : .trailing)
                    .foregroundStyle(.accent)
            }
        }
        .padding(.bottom, 36)
    }
    
    private var tabView: some View {
        
        ZStack(alignment: .bottom) {
            
            TabView (selection: $selectedTabIndex.animation(.easeInOut(duration: 0.1))) {
                
                    ScrollView {
                        VStack (alignment: .leading){
                            
                            
                            passionOptionSection(sectionImage: "figure.socialdance", sectionTitle: "Social", options: socialPassions, selectedIndex: $socialPassionsSelectedIndex, selectedPassions: $selectedPassions)
                            
                            passionOptionSection(sectionImage: "book", sectionTitle: "Interests", options: interests, selectedIndex: $interestsSelectedIndex, selectedPassions: $selectedPassions)
                            
                            passionOptionSection(sectionImage: "MyCustomShoe", sectionTitle: "Activities", options: activities, selectedIndex: $activitiesSelectedIndex, selectedPassions: $selectedPassions)
                            
                            passionOptionSection(sectionImage: "tennisball", sectionTitle: "Sports", options: sportsPassions, selectedIndex: $sportsPassionsSelectedIndex, selectedPassions: $selectedPassions)
                            
                            passionOptionSection(sectionImage: "MyCustomMic", sectionTitle: "Music", options: music1, isMusic: true, selectedIndex: $music1SelectedIndex, selectedPassions: $selectedPassions)
                            
                            passionOptionSection(sectionImage: " ", sectionTitle: " ", options: music2, isMusic: true, selectedIndex: $music2SelectedIndex, selectedPassions: $selectedPassions)

                            passionOptionSection(sectionImage: " ", sectionTitle: " ", options: music3, selectedIndex: $music3SelectedIndex, selectedPassions: $selectedPassions)
                        }
                    }
                .tag(0)
                
                //Page 2
                VStack{

                    ZStack{
                        InputTextfield(placeholder: "Add your Own", inputtedText: $textFieldText, textSize: 20, isFocused: $isFocused, alignment: .center)
                            .padding(.top, 60)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.grayPlaceholder, lineWidth: 2)
                                .background(Circle().fill(Color.white))
                                .frame(width: 22, height: 22)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 16))
                                .foregroundStyle(textFieldText.count < 2 ? .gray : .accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .offset(x: -24, y: 24)
                        .onTapGesture {
                            
                            guard !textFieldText.isEmpty else { return}
                            
                            selectedPassions.append(textFieldText)
                            customText.append(textFieldText)
                            textFieldText = ""
                        }
                    }
                    optionCell(myInputText: $customText, selectedPassions: $selectedPassions)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 10)
                    .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .tag (1)
            }
            .tabViewStyle(PageTabViewStyle())
            
            NextButton(isEnabled: selectedPassions.count > 2, onInvalidTap: {})
                .padding(.bottom, selectedTabIndex == 0 ? 72 : 16)
        }
    }
}

    


struct passionOptionSection: View {
    
    let sectionImage: String
    
    let sectionTitle: String
    
    var options: [String]
    
    var isMusic: Bool = false
    
    @Binding var selectedIndex : Int?
    
    @Binding var selectedPassions: [String]
    
    
    var body: some View {
        
        VStack (alignment: .leading) {
            
            // The Title Section
            HStack(alignment: .center, spacing: 21) {
                    if UIImage(systemName: sectionImage) != nil {
                        Image(systemName: sectionImage)
                            .resizable()
                            .frame(width: 22, height: 20)
                    } else {
                        Image(sectionImage)
                            .resizable()
                            .frame(width: 22, height: 20)
                    }
                
                Text(sectionTitle)
                    .font(.body(20))
                    .offset(y: 1)
            }
            .padding(.horizontal, 5)
            .padding(.bottom, 16)
            
            // The Contents Section
            FlowLayout(mode: .scrollable, items: Array(0..<options.count), itemSpacing: 6) { index in
                Button {
                    if selectedPassions.contains(options[index]) {
                        selectedPassions.removeAll { $0 == options[index] }
                    } else if selectedPassions.count < 5 {
                        selectedPassions.append(options[index])
                    }
                    
                } label: {
                    Text(options[index])
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .font(.body(14))
                        .background(
                          RoundedRectangle(cornerRadius: 10)
                            .fill(selectedPassions.contains(options[index]) ? Color.accent : .clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 1)
                        )
                        .foregroundStyle(selectedPassions.contains(options[index]) ? .white : .black)
                }
            }
        }
        .padding(.bottom, isMusic ? -24 : 48)
    }
}


struct optionCell: View {
    
    @Binding var myInputText: [String]
    
    @Binding var selectedPassions: [String]
    
    var body: some View {
        
        VStack(spacing: 12){
            
            FlowLayout(mode: .scrollable, items: myInputText, itemSpacing: 12) {index in
                    ZStack (alignment: .topTrailing) {
                        Text(index)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 10)
                            .font(.body(14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 1)
                            )
                        ZStack {
                            Circle()
                                .stroke(Color.gray, lineWidth: 1)
                                .background(Circle().fill(Color.white))
                                .frame(width: 16, height: 16)
                            
                            Image(systemName:"xmark")
                                .font(.system(size: 10))
                                .foregroundStyle(.black)
                        }
                        .offset(x: 4, y: -6)
                }
                .onTapGesture {
                    self.myInputText.removeAll(where: { $0 == index })
                    self.selectedPassions.removeAll(where: { $0 == index })
                }
            }
        }
    }
}
