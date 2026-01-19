//
//  InfoView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.

import SwiftUI

struct InfoView: View {
    
    @Bindable var vm: EditProfileViewModel
    @FocusState var isFocused: Bool
    
    private var coreInfo: [EditPreview] {
         let u = vm.draft /*else { return [] }*/
        return [
            EditPreview("Name", [u.name], route: .textField(.name)),
            EditPreview("Sex", [u.sex], route: .option(.sex)),
            EditPreview("Attracted To", [u.attractedTo], route: .option(.attractedTo)),
            EditPreview("Year", [u.year], route: .option(.year)),
            EditPreview("Height", [u.height], route: .height),
            EditPreview("Nationality", [u.nationality.joined(separator: ", ")], route: .nationality)
        ]
    }

    
    private var aboutMe: [EditPreview] {
         let u = vm.draft /* else { return [] }*/
        let spacer = String(repeating: " ", count: 3)
        let lifestyle =
        "🍻 \(u.drinking.lowercased()) " + spacer +
        "🚬 \(u.smoking.lowercased())" + spacer +
        "🌿 \(u.marijuana.lowercased()) " + spacer +
        "💊 \(u.drugs.lowercased())"
        
        let myLifeAs: [String] = {
            let choices = [
                u.favouriteMovie.map { "🎬 \($0)" },
                u.favouriteSong.map { "🎶 \($0)" },
                u.favouriteBook.map { "📗 \($0)" }
            ].compactMap { $0 }
            return choices.isEmpty ? [] : choices
        }()
        return [
            EditPreview("Looking For", [u.lookingFor], route: .option(.lookingFor)),
            EditPreview("Degree", [u.degree], route: .textField(.degree)),
            EditPreview("Hometown", [u.hometown], route: .textField(.hometown)),
            EditPreview("Lifestyle", [lifestyle], route: .lifestyle),
            EditPreview("Favourite Media", [myLifeAs.joined(separator: ", ")], route: .myLifeAs),
            EditPreview("Languages", u.languages, route: .languages)
        ]
    }

    var body: some View {
        let sections: [(title: String, data: [EditPreview])] = [
            ("Core", coreInfo), ("About", aboutMe)]
        
        ScrollView {
            VStack(spacing: 36) {
                ForEach(sections, id: \.title) {section in
                    CustomList(title: section.title) {
                        ForEach(section.data) { info in
                            VStack(spacing: 0) {
                                ListItem(title: info.title, response: info.response, value: info.route)
                                if info.id != section.data.last?.id {
                                        SoftDivider()
                                            .padding(.leading, 24)
                                            .foregroundStyle(.red)
                                    }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
}
struct EditPreview: Identifiable {

    let id =  UUID()
    let title: String
    let response: [String]
    let route: EditProfileRoute
    
    init(_ title: String, _ response: [String], route: EditProfileRoute) {
        self.title = title
        self.response = response
        self.route = route
    }
}





        
        
        

