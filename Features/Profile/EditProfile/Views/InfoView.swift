//
//  InfoView.swift
//  Scoop
//
//  Created by Art Ostin on 28/07/2025.

import SwiftUI

struct CoreInfo: View {

    //Injected
    @Bindable var vm: EditProfileViewModel

    private var items: [EditPreview] {
        let u = vm.draft
        return [
            EditPreview("Name", [u.name], route: .textField(.name)),
            EditPreview("Sex", [u.sex], route: .option(.sex)),
            EditPreview("Year", [u.year], route: .option(.year)),
            EditPreview("Height", [u.height], route: .height),
            EditPreview("Nationality", [u.nationality.joined(separator: "  ")], route: .nationality)
        ]
    }

    var body: some View {
        Section("Core") {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, info in
                ListItem(title: info.title, response: info.response, value: info.route)
                    .padding(.top, index == 0 ? Spacing.xs : 0)
                    .padding(.bottom, index == items.count - 1 ? Spacing.xs : 0)
            }
        }
    }
}

struct ExtraInfo: View {
    //Injected
    @Bindable var vm: EditProfileViewModel

    private var items: [EditPreview] {
        let u = vm.draft
        let lifestyle = ["🍻 \(u.drinking)", "💊 \(u.drugs)", "🌿 \(u.marijuana) ", "🚬 \(u.smoking)"].joined(separator: "   ")

        let favouriteMedia: [String] = [
            u.favouriteMovie.map { "🎬 \($0)" },
            u.favouriteSong.map { "🎶 \($0)" },
            u.favouriteBook.map { "📗 \($0)" }
        ].compactMap { $0 }

        return [
            EditPreview("Seeking", [u.lookingFor], route: .option(.lookingFor)),
            EditPreview("Degree", [u.degree], route: .textField(.degree)),
            EditPreview("Hometown", [u.hometown], route: .textField(.hometown)),
            EditPreview("Vices", [""], route: .lifestyle),
            EditPreview("Media", [favouriteMedia.joined(separator: "    ")], route: .myLifeAs),
            EditPreview("Languages", u.languages, route: .languages)
        ]
    }

    var body: some View {
        Section("Extra") {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, info in
                ListItem(title: info.title, response: info.response, value: info.route)
                    .padding(.top, index == 0 ? Spacing.xs : 0)
                    .padding(.bottom, index == items.count - 1 ? Spacing.xs : 0)
            }
        }
    }
}


struct EditPreview: Identifiable {

    let title: String
    let response: [String]
    let route: EditProfileRoute

    var id: EditProfileRoute { route }

    init(_ title: String, _ response: [String], route: EditProfileRoute) {
        self.title = title
        self.response = response
        self.route = route
    }
}
