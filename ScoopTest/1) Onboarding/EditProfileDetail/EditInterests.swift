//
//  EditPassions.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI
import SwiftUIFlowLayout
import FirebaseFirestore


@Observable class InterestsOptionsViewModel {
    
    var socialPassions: [String] = [ "Bars", "Raves", "Clubbing", "Movie Nights", "House Party", "Darties", "Dinner Parties", "Road Trips", "Concerts", "Wine n Dine", "Pub", "Game Nights", "Brunch", "Festival", "Karoke"]
    var interests: [String] = [ "Reading", "Poetry","Cold Swimming", "Sport","Writing", "Photography", "Museums", "Psychology", "Anime", "Nature", "Fashion", "Astronomy", "Movies", "Entrepreneurship", "Philosophy", "Formula 1", "Volunteering", "Politics", "Art", "Podcasts", "Food", "Music"]
    var activities = ["Camping", "Hiking", "Backpacking", "Beach", "Road Trips", "Thrifting", "Cooking", "Chess", "Board Games", "Table Tennis", "Socialising", "Gaming", "Acting", "Drawing", "Painting", "Djing", "Meditation", "Partying"]
    var sportsPassions = ["Badminton", "Rugby", "Baseball", "Soccer", "Basketball", "Tennis", "Football", "Handball", "Lacrosse", "Volleyball", "Softball", "Boxing", "Athletics", "Cycling", "Running", "Rowing", "Gym/Fitness", "Martial Arts", "Skateboarding", "Ice Hockey", "Pilates", "Yoga", "Kayaking", "Roller Skating", "Climbing", "Ultimate Frisbee", "Ice Skating", "Snowboarding", "Darts", "Golf", "Mountain Biking", "Bouldering", "Quidditch", "Surfing", "Skiing", "Sailing", "Spikeball", "Shooting", "Squash", "Fencing"]
    var music1 = ["Pop", "Rock", "Hip-Hop", "Grime", "R & B", "Country", "Reggae", "Soul", "Jazz", "Funk", "Blues", "Acoustic", "Folk", "Latin Pop", "Disco", "K-Pop", "Afrobeat", "Metal", "Classical", "Chill", "Retro Bangers"]
    var music2 = ["EDM", "House", "Techno", "Trance", "D & B", "Dance", "Dubstep", "Electronica", "Ambient", "Tech House", "Melodic Techno", "Psytrance", "Big Room", "Acid", "Garage", "Afro tech", "Tropical House", "Jungle", "Liquid"]
    var music3 = ["Indie", "Indie pop", "Indie Rock", "Lo-fi", "Shoegaze", "Dream Pop", "Psychedelic Rock", "Grunge", "Emo", "Post-Rock", "Slowcore", "Folk Music", "Experimental", "Punk"]
}

struct EditInterests: View {
    
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    @State var selected: [String] = []
    
    @State private var vm: InterestsOptionsViewModel

    let sections: [(title: String?, image: String?, data: [String])]
    let title: String
    var isOnboarding: Bool
    
    @Binding var screenTracker: OnboardingViewModel
    
    init(
        sections: [(title: String?, image: String?, data: [String])]? = nil,
        title: String,
        isOnboarding: Bool,
        screenTracker: Binding<OnboardingViewModel>? = nil
    ) {
        let model = InterestsOptionsViewModel()
        self._vm = State(initialValue: model)
        self._selected = State(initialValue: [])
        self._screenTracker =  screenTracker ?? .constant(OnboardingViewModel())
        self.sections = sections ?? [
          ("Social",    "figure.socialdance", model.socialPassions),
          ("Interests", "book",               model.interests),
          ("Activities","MyCustomShoe",       model.activities),
          ("Sports",    "tennisball",         model.sportsPassions),
          ("Music",     "MyCustomMic",        model.music1),
          (nil,         nil,                  model.music2),
          (nil,         nil,                  model.music3),
        ]
        
        self.title = title
        self.isOnboarding = isOnboarding
    }
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 12) {
                
                SignUpTitle(text: title, subtitle: "\(selected.count)/10")
                
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
                .padding(.horizontal)
                ScrollView(.vertical) {
                    
                    LazyVStack(spacing: 0) {
                        
                        ForEach(sections.indices, id: \.self) { idx in
                            let section = sections[idx]
                            
                            InterestSection(options: section.data, title: section.title, image: section.image, selected: $selected)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .customNavigation(isOnboarding: isOnboarding)
            .padding(.top, 12)
            
            if isOnboarding {
                NextButton(isEnabled: selected.count > 4, onTap: {screenTracker.screen += 1})
                    .padding(.top, 524)
                    .padding(.horizontal)
            }
        }
    }
}



struct InterestSection: View {
    
    @State var options: [String]
    
    let title: String?
    let image: String?
    
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies

    
    private func interestIsSelected (text: String) -> Bool {
        dependencies.userStore.user?.interests?.contains(text) == true
    }
    
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
                    selected.contains(text)
                        ? selected.removeAll(where: { $0 == text })
                        : (selected.count < 10 ? selected.append(text) : nil)

                    Task {
                        if interestIsSelected(text: text) {
                            try await dependencies.profileManager.update(values: [.interests : FieldValue.arrayRemove([text])])
                        } else {
                            try await dependencies.profileManager.update(values: [.interests : FieldValue.arrayRemove([text])])
                        }
                    }
                }
            }
            .offset(x: -5)
        }
        .padding(.bottom, (title == nil || title == "Music") ? 0 : 60)
        
    }
}

//#Preview {
//    EditInterests()
//}


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
                    .fill(selection.contains(text) ? .accent : Color.background)
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
