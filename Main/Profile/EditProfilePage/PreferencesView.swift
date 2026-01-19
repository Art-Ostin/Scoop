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
        
        CustomList(title: "Dating Preferences (Not Public)") {
            ForEach(preferences) { info in
                VStack(spacing: 0) {
                    
                    
                    ListItem(title: info.title, response: info.response, value: info.route)
                    if info.title != "Age Preference" {
                        SoftDivider()
                            .padding(.leading, 24)
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 48)
    }
}
