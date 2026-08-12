//
//  PreferencesView.swift
//  Scoop
//
//  Created by Art Ostin on 19/01/2026.
//

import SwiftUI

struct PreferencesView: View {
    
    @Bindable var vm: EditProfileViewModel
    private var preferences: [EditPreview] {
        let p = vm.draft
        return [
            EditPreview("Attracted To", [p.attractedTo], route: .option(.attractedTo)),
            EditPreview("Age Preference", p.preferredYears, route: .desiredAgeRange)
        ]
    }
    
    var body: some View {
        Section {
            ForEach(preferences) { info in
                ListItem(title: info.title, response: info.response, value: info.route)
            }
        } header: {
            HStack(alignment: .bottom) {
                //Bare, so it keeps the section header's own styling — only the note opposite it is styled
                Text("Preferences")
                Spacer()
                //These fields feed matching, they are not profile content: says so before the rows are read
                Text("Not visible on profile")
                    .font(.body(12))
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
}
