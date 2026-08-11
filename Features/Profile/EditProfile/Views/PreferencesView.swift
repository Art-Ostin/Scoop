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
        Section("Dating Preferences (Not Public)") {
            ForEach(preferences) { info in
                ListItem(title: info.title, response: info.response, value: info.route)
            }
        }
    }
}
