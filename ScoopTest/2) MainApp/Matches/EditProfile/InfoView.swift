//
//  InfoView.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.


import SwiftUI

struct InfoView: View {
    
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    @Binding var vm: EditProfileViewModel
    
    //Populate the coreInfo and aboutMe with the UserProfile 
    private var coreInfo: [ProfileInfoPreview<AnyView>] {
        

        guard let u = dependencies.userStore.user else { return [] }
        
        let name       = u.name        ?? "–"
        let sex        = u.sex         ?? "–"
        let attracted  = u.attractedTo ?? "–"
        let year       = u.year        ?? "–"
        let height     = u.height      ?? "–"
        let nationality = u.nationality ?? []
        
        return [
            .init("Name", [name]) {AnyView(EditTextFieldLayout(isOnboarding: false, title: "Name", vm: $vm))},
            .init("Sex", [sex]) {AnyView(EditSex(title: "Sex", vm: $vm))},
            .init("Attracted to", [attracted]) {AnyView(EditAttractedTo(title: "Attracted to", vm: $vm))},
            .init("Year", [year]) {AnyView(EditYear(title: "Year", vm: $vm))},
            .init("Height", [height]) {AnyView(EditHeight(title: "Height", vm: $vm))},
            .init("Nationality", nationality) {AnyView(EditNationality(isOnboarding: false))}
        ]
    }
    
    private var aboutMe: [ProfileInfoPreview<AnyView>] {
        
        guard let u = dependencies.userStore.user else { return [] }

        let lookingFor = u.lookingFor ?? "–"
        let degree = u.degree ?? "-"
        let hometown = u.hometown ?? "-"
        
        let lifestyle = "Drinking:  \(u.drinking?.lowercased() ?? "-"),   "
                      + "Smoking:  \(u.smoking?.lowercased() ?? "-"),   "
                      + "Marijuana:  \(u.marijuana?.lowercased() ?? "-"),   "
                      + "Drugs:  \(u.drugs?.lowercased() ?? "-")"
        
        let myLifeAs: [String] = {
            let choices = [
                u.favouriteMovie.map { "Movie: \($0)" },
                u.favouriteSong.map { "Song: \($0)" },
                u.favouriteBook.map { "Book: \($0)" }
            ].compactMap { $0 }
            return choices.isEmpty ? ["Add information"] : choices
        }()
        let languages = u.languages  ?? "Add Languages"
        return [
            .init("Looking for", [lookingFor]){AnyView( EditLookingFor(vm: $vm))},
            .init("Degree", [degree]){AnyView(EditTextFieldLayout(isOnboarding: false, title: "Degree", vm: $vm))},
            .init("Hometown", [hometown]){AnyView(EditTextFieldLayout(isOnboarding: false, title: "Hometown", vm: $vm))},
            .init("Lifestyle",[lifestyle]) {AnyView(EditLifestyle(vm: $vm))},
            .init("My Life as a", myLifeAs) {AnyView(EditMyLifeAs())},
            .init ("Languages", [languages]) {AnyView(EditTextFieldLayout(isOnboarding: false, title: "I Speak", vm: $vm))}
        ]
    }

    @FocusState var isFocused: Bool

    var body: some View {
        
        let sections: [(title: String, data: [ProfileInfoPreview<AnyView>])] = [
            ("Core", coreInfo), ("About", aboutMe)]
        
        
        
        ScrollView {
            ForEach(sections, id: \.title) {section in
                CustomList(title: section.title) {
                    ForEach(section.data) { info in
                        VStack(spacing: 0) {
                                ListItem(title: info.title, response: info.response, destination: info.destination)
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
        .padding(.horizontal, 32)
    }
}
//
//#Preview {
//    InfoView()
//}

struct ProfileInfoPreview<Content: View>: Identifiable {
    let id = UUID()
    let title: String
    let response: [String]
    let destination: () -> Content
    
    init(_ title: String, _ response: [String], @ViewBuilder _ destination: @escaping () -> Content) {
        self.title = title
        self.response = response
        self.destination = destination
    }
}
