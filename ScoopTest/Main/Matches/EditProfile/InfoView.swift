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
        let u = vm.draftUser
        return [
            EditPreview("Name", [u.name ?? ""]) {
                       TextFieldEdit(vm: vm, field: .name)
                   },
                   EditPreview("Sex", [u.sex ?? ""]) {
                       OptionEditView(vm: vm, field: .sex)
                   },
                   EditPreview("Attracted To", [u.attractedTo ?? ""]) {
                       OptionEditView(vm: vm, field: .attractedTo)
                   },
                   EditPreview("Year", [u.year ?? ""]) {
                       OptionEditView(vm: vm, field: .year)
                   },
                   EditPreview("Height", [u.height ?? ""]) {
                       EditHeight(vm: vm)
                   },
                   EditPreview("Nationality", [u.nationality?.joined(separator: ", ") ?? ""]) {
                       EditNationality(vm: vm)
                   }
        ]
    }
    private var aboutMe: [EditPreview] {
        let u = vm.draftUser

        let lifestyle =
        "Drinking: \(u.drinking?.lowercased() ?? "-"), " +
        "Smoking: \(u.smoking?.lowercased() ?? "-"), " +
        "Marijuana: \(u.marijuana?.lowercased() ?? "-"), " +
        "Drugs: \(u.drugs?.lowercased() ?? "-")"
        
        let myLifeAs: [String] = {
            let choices = [
                u.favouriteMovie.map { "Movie: \($0)" },
                u.favouriteSong.map { "Song: \($0)" },
                u.favouriteBook.map { "Book: \($0)" }
            ].compactMap { $0 }
            return choices.isEmpty ? ["Add information"] : choices
        }()
        
        return [
            EditPreview("Looking For", [u.lookingFor ?? ""]) {
                OptionEditView(vm: vm, field: .lookingFor)
            },
            EditPreview("Degree", [u.degree ?? ""]) {
                TextFieldEdit(vm: vm, field: .degree)
            },
            EditPreview("Hometown", [u.hometown ?? ""]) {
                TextFieldEdit(vm: vm, field: .hometown)
            },
            
            EditPreview("Lifestyle", [lifestyle]) {
                EditLifestyle()
            },
            EditPreview("My Life as a", [myLifeAs.joined(separator: ", ")]) {
                EditMyLifeAs(vm: vm)
            },
            EditPreview("Languages", [u.languages ?? ""]) {
                TextFieldEdit(vm: vm, field: .languages)
            }
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
struct EditPreview: Identifiable {

    let id =  UUID()
    let title: String
    let response: [String]
    let destination: AnyView
    
    init<Content : View> (_ title: String, _ response: [String], @ViewBuilder _ destination: @escaping () -> Content) {
        self.title = title
        self.response = response
        self.destination = AnyView(destination())
    }
}





        
        
        
