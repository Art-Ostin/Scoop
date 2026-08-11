//
//  InterestsView.swift
//  Scoop
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct InterestsLayout: View {
    
    var passions: [String]
    
    let forProfile: Bool
    
    
    private var rows: [[String]] {
        stride(from: 0, to: passions.count, by: 2).map {
            Array(passions[$0..<min($0+2, passions.count)])
        }
    }
    
    var body: some View {
        VStack(spacing: forProfile ? Spacing.sm : Spacing.md) {
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]
                HStack {
                    Text(row[safe: 0] ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                        .frame(height: 20)
                    
                    Text(row.count > 1 ? row[1] : "")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                if index < rows.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .font(.body())
        .foregroundStyle(passions.count < 1 ? Color.textAccent : Color.textPrimary)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill( Color.white)
        )
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}


struct InterestsView: View {

    //Injected
    @Bindable var vm: EditProfileViewModel
    @Binding var path: [EditProfileRoute]

    var body: some View {
        Section("Interests & Character") {
            //A Button, not a NavigationLink: the card carries its own chrome and takes no disclosure chevron
            Button { path.append(.interests) } label: {
                InterestsLayout(passions: vm.draft.interests, forProfile: false)
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: Spacing.xxs, leading: Spacing.md,
                                      bottom: Spacing.xxs, trailing: Spacing.md))
        }
    }
}
