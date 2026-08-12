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

//MARK: - Vices

//How often a user does a given vice — drives the glyph above its icon.
enum ViceStatus { case yes, no, occasionally }

//One vice: its status glyph stacked above its icon.
struct ViceItem: View {
    let icon: String
    let status: ViceStatus
    var iconSize: CGFloat = 20
    var glyphHeight: CGFloat = 7 //The tallest glyph's natural height, so the two rows stay pinned

    var body: some View {
        VStack(spacing: Spacing.xs) {
            //Fixed boxes for both rows, so the four items align regardless of glyph or icon proportions
            Rectangle()
                .fill(Color.clear)
                .frame(width: iconSize, height: glyphHeight)
                .overlay { glyph }

            Rectangle()
                .fill(Color.clear)
                .frame(width: iconSize, height: iconSize)
                .overlay {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                }
        }
        .foregroundStyle(Color.textPrimary)
    }

    //Drawn at natural size, never .resizable(): these are stroked vectors, so scaling one would
    //scale its 1.2pt stroke and break the weight match between them.
    @ViewBuilder
    private var glyph: some View {
        switch status {
        case .yes: Image("TickSVG")
        case .occasionally: Image("Tilde")
        //TODO: draw a cross at the same 1.2 stroke as TickSVG/Tilde — this symbol only stands in
        case .no: Image(systemName: "xmark").font(.icon(9, .semibold))
        }
    }
}

struct VicesRow: View {
    let drinking: ViceStatus
    let smoking: ViceStatus
    let marijuana: ViceStatus
    let drugs: ViceStatus

    private var items: [(icon: String, status: ViceStatus)] {
        [("ScoopDrinkIcon", drinking), ("ScoopCigaretteIcon", smoking),
         ("ScoopWeedIcon", marijuana), ("ScoopDrugIcon", drugs)]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.icon) { item in
                ViceItem(icon: item.icon, status: item.status)
                    .frame(maxWidth: .infinity) //Equal columns, so each glyph stays centred on its own icon
            }
        }
    }
}

#Preview {
    VicesRow(drinking: .yes, smoking: .yes, marijuana: .occasionally, drugs: .no)
        .padding(.horizontal, Spacing.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appCanvas)
}
