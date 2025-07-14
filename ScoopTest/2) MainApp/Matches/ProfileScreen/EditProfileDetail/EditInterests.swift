//
//  EditPassions.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI
import SwiftUIFlowLayout


@Observable class InterestsOptionsViewModel {
    
    var socialPassions: [String] = [ "Bars", "Raves", "Clubbing", "Movie Nights", "House Party", "Darties", "Dinner Parties", "Road Trips", "Concerts", "Wine n Dine", "Pub", "Game Nights", "Brunch", "Festival", "Karoke"]
    var interests: [String] = [ "Reading", "Poetry","Cold Water Swimming", "Sport","Writing", "Photography", "Museums", "Psychology", "Anime", "Nature", "Fashion", "Astronomy", "Movies", "Entrepreneurship", "Philosophy", "Formula 1", "Volunteering", "Politics", "Art", "Podcasts", "Food", "Music"]
    var activities = ["Camping", "Hiking", "Backpacking", "Beach", "Road Trips", "Thrifting", "Cooking", "Chess", "Board Games", "Table Tennis", "Socialising", "Gaming", "Acting", "Drawing", "Painting", "Djing", "Meditation", "Partying"]
    var sportsPassions = ["Badminton", "Rugby", "Baseball", "Soccer", "Basketball", "Tennis", "Football", "Handball", "Lacrosse", "Volleyball", "Softball", "Boxing", "Athletics", "Cycling", "Running", "Rowing", "Gym/Fitness", "Martial Arts", "Skateboarding", "Ice Hockey", "Pilates", "Yoga", "Kayaking", "Roller Skating", "Climbing", "Ultimate Frisbee", "Ice Skating", "Snowboarding", "Darts", "Golf", "Mountain Biking", "Bouldering", "Quidditch", "Surfing", "Skiing", "Sailing", "Spikeball", "Shooting", "Squash", "Fencing"]
    var music1 = ["Pop", "Rock", "Hip-Hop", "Grime", "R & B", "Country", "Reggae", "Soul", "Jazz", "Funk", "Blues", "Acoustic", "Folk", "Latin Pop", "Disco", "K-Pop", "Afrobeat", "Metal", "Classical", "Chill", "Retro Bangers"]
    var music2 = ["EDM", "House", "Techno", "Trance", "D & B", "Dance", "Dubstep", "Electronica", "Ambient", "Tech House", "Melodic Techno", "Psytrance", "Big Room", "Acid", "Garage", "Afro tech", "Tropical House", "Jungle", "Liquid"]
    var music3 = ["Indie", "Indie pop", "Indie Rock", "Lo-fi", "Shoegaze", "Dream Pop", "Psychedelic Rock", "Grunge", "Emo", "Post-Rock", "Slowcore", "Folk Music", "Experimental", "Punk"]
}


struct EditInterests: View {
    
    @State var selected: [String] = []
    @State var vm = InterestsOptionsViewModel()
    
    var body: some View {
        
        let sections: [(title: String?, image: String?, data: [String])] = [
            ("Social", "figure.socialdance", vm.socialPassions),
            ("Interests", "book", vm.interests),
            ("Activities", "MyCustomShoe", vm.activities),
            ("Sports", "tennisball", vm.sportsPassions),
            ("Music", "MyCustomMic", vm.music1),
            (nil, nil, vm.music2),
            (nil, nil, vm.music3)
        ]
        
        VStack(spacing: 12) {
            
            SignUpTitle(text: "Interests", subtitle: "\(selected.count)/10")
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selected, id: \.self) { item in
                            
                            optionCell2(text: item, selection: $selected) {text in
                                selected.removeAll { $0 == text }
                            }
                            .id(item)
                        }
                    }
                    .frame(height: 40)
                }
                .onChange(of: selected.count) {
                  withAnimation {
                      proxy.scrollTo(selected.last, anchor: .trailing)
                  }
                }
            }

            ScrollView(.vertical) {
                
                LazyVStack(spacing: 0) {
                    
                    ForEach(sections.indices, id: \.self) { idx in
                        let section = sections[idx]
                        
                            InterestSection(options: section.data, title: section.title, image: section.image, selected: $selected)
                    }
                }
            }
            
        }
        .padding(.horizontal, 24)
        .padding(.top, 36)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CustomBackButton()
            }
        }
    }
}
struct InterestSection: View {
    
    @State var options: [String]
    
    let title: String?
    let image: String?
    
    @Binding var selected: [String]
    
    var body: some View {
        
        VStack(alignment: .leading) {
                        
            HStack(alignment: .center, spacing: 24) {
                if let image = image {
                    Image(image)
                        .resizable()
                        .frame(width: 22, height: 20)
                }
                if let title = title {
                    Text(title)
                        .font(.body(20))
                        .offset(y: 1)
                }
            }
            .padding(.horizontal, 5)
            .padding(.bottom, 16)
                        
            FlowLayout(mode: .scrollable, items: options, itemSpacing: 6) { input in
                optionCell2(text: input, selection: $selected) { text in
                    selected.contains(text) ? selected.removeAll(where: { $0 == text }) : (selected.count < 10 ? selected.append(text) : nil)
                }
            }
            .offset(x: -5)
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CustomBackButton()
            }
        }
        .padding(.bottom, (title == nil || title == "Music") ? 0 : 60)

    }
}

#Preview {
    EditInterests()
}
struct optionCell2: View {
    
    let text: String
    
    @Binding var selection: [String]
    
    let onTap: (String) -> Void
    
    var body: some View {
        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .font(.body(14))
            .foregroundStyle(selection.contains(text) ? Color.white : Color.black)
            .background (
                RoundedRectangle(cornerRadius: 12)
                    .fill(selection.contains(text) ? .accent : .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 1)
                    )
                )
            .onTapGesture {
                onTap(text)
            }
    }
}
