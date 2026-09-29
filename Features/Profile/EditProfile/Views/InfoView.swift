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
            EditPreview(title: "Name", response: [u.name], route: .textField(.name)),
            EditPreview(title: "Sex", response: [u.sex], route: .option(.sex)),
            EditPreview(title: "Year", response: [u.year], route: .option(.year)),
            EditPreview(title: "Height", response: [u.height], route: .height),
            EditPreview(title: "Nationality", response: [u.nationality.joined(separator: "  ")], route: .nationality)
        ]
    }

    var body: some View {
        Section("Core") {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, info in
                ListItem(title: info.title, response: info.response, value: info.route,
                         showsDivider: index < items.count - 1)
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
            EditPreview(title: "Seeking", subHeading: u.lookingForText, response: [u.lookingFor], route: .lookingFor),
            EditPreview(title: "Degree", response: [u.degree], route: .textField(.degree)),
            EditPreview(title: "Hometown", response: [u.hometown], route: .textField(.hometown)),
            EditPreview(title: "Vices", response: [""], route: .lifestyle),
            EditPreview(title: "Media", response: [favouriteMedia.joined(separator: "    ")], route: .myLifeAs),
            EditPreview(title: "Languages", response: u.languages, route: .languages)
        ]
    }

    var body: some View {
        Section("Extra") {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, info in
                ListItem(title: info.title, subHeading: info.subHeading, response: info.response, value: info.route,
                         showsDivider: index < items.count - 1)
                    .padding(.top, index == 0 ? Spacing.xs : 0)
                    .padding(.bottom, index == items.count - 1 ? Spacing.xs : 0)
            }
        }
    }
}

struct EditPreview: Identifiable {
    let title: String
    let subHeading: String?
    let response: [String]
    let route: EditProfileRoute

    var id: EditProfileRoute { route }

    init(title: String, subHeading: String? = nil, response: [String], route: EditProfileRoute) {
        self.title = title
        self.subHeading = subHeading
        self.response = response
        self.route = route
    }
}
