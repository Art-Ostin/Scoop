//
//  InfoView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.

import SwiftUI

struct InfoView: View {
    
    @Environment(\.appDependencies) private var dep
    @FocusState var isFocused: Bool
    
    private var coreInfo: [EditPreview] {
        guard let u = dep.userManager.user else { return [] }
        return [
            .init("Name", [u.name ?? ""], {TextFieldEdit(field: ProfileFields.editName(dep:dep))}),
            .init("Sex", [u.sex ?? ""], {OptionEditView(field: ProfileFields.editSex(dep:dep))}),
            .init("AttractedTo", [u.attractedTo ?? ""], {OptionEditView(field: ProfileFields.editAttractedTo(dep:dep))}),
            .init("Year", [u.year ?? ""], {OptionEditView(field: ProfileFields.editYear(dep:dep))}),
            .init("Height", [u.height ?? ""], {EditHeight()}),
            .init("Nationality", [u.nationality?.joined() ?? ""], {EditNationality()})
        ]
    }
    
    private var aboutMe: [EditPreview] {
        guard let u = dep.userManager.user else { return [] }
        
        let lifestyle = "Drinking:  \(u.drinking?.lowercased() ?? "-"), " + "Smoking:  \(u.smoking?.lowercased() ?? "-"), " + "Marijuana: \(u.marijuana?.lowercased() ?? "-"), " + "Drugs:  \(u.drugs?.lowercased() ?? "-")"
        let myLifeAs: [String] = {
            let choices = [
                u.favouriteMovie.map { "Movie: \($0)" },
                u.favouriteSong.map { "Song: \($0)" },
                u.favouriteBook.map { "Book: \($0)" }
            ].compactMap { $0 }
            return choices.isEmpty ? ["Add information"] : choices
        }()
        return [
            .init("Looking For", [u.lookingFor ?? ""], {OptionEditView(field: ProfileFields.editLookingFor(dep:dep)) }),
            .init("Degreee", [u.degree ?? ""], {TextFieldEdit(field: ProfileFields.editDegree(dep:dep))}),
            .init("Hometown", [u.hometown ?? ""], {TextFieldEdit(field: ProfileFields.editHometown(dep:dep))}),
            .init("Lifestyle", [lifestyle], {EditLifestyle()}),
            .init("My Life as a", [myLifeAs.joined(separator: ",")], {EditMyLifeAs()}),
            .init("Languages", [u.languages ?? ""], {TextFieldEdit(field: ProfileFields.editLanguages(dep:dep))})
        ]
    }
    
    var body: some View {

        let sections: [(title: String, data: [EditPreview])] = [
            ("Core", coreInfo), ("About", aboutMe)]

        ScrollView {
            ForEach(sections, id: \.title) {section in
                CustomList(title: section.title) {
                    ForEach(section.data) { info in
                        VStack(spacing: 0) {
                            ListItem(title: info.title, response: info.response) {info.destination }
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

#Preview {
    InfoView()
}

struct EditPreview: Identifiable {
    let id = UUID()
    let title: String
    let response: [String]
    let destination: AnyView
    
    init<Content : View> (_ title: String, _ response: [String], @ViewBuilder _ destination: @escaping () -> Content) {
        self.title = title
        self.response = response
        self.destination = AnyView(destination())
    }
}





        
        
        
