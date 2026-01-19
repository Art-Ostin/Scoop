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
            EditPreview("Age Preference", [p.desiredAgeRange], route: .desiredAgeRange)),
            
        ]
    }
    
    
    private var coreInfo: [EditPreview] {
         let u = vm.draft /*else { return [] }*/
        return [
            EditPreview("Name", [u.name], route: .textField(.name)),
            EditPreview("Sex", [u.sex], route: .option(.sex)),
            EditPreview("Attracted To", [u.attractedTo], route: .option(.attractedTo)),
            EditPreview("Year", [u.year], route: .option(.year)),
            EditPreview("Height", [u.height], route: .height),
            EditPreview("Nationality", [u.nationality.joined(separator: ", ")], route: .nationality)
        ]
    }

    
    
    var body: some View {
        
    }
}
