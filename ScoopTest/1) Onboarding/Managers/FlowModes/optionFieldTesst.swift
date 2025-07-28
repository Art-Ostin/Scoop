//
//  optionFieldTesst.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct optionFieldTesst: View {
    
    @Environment(\.appDependencies) private var deps
    
    private var attractedToField: OptionField {
        OptionField(
            title: "Attracted To",
            options: ["Men", "Women", "Men & Women", "All Genders"],
            keyPath: \.attractedTo
        ) { value in
            try? await deps.profileManager.update(values: [.attractedTo: value])
        }
    }
    
    
    private var yearField: OptionField {
         OptionField(
             title: "Year",
             options: ["U0", "U1", "U2", "U3", "U4"],
             keyPath: \.year
         ) { value in
             try? await deps.profileManager.update(values: [.year: value])
         }
     }
    
    private var attractedField: OptionField {
        OptionField(
            title: "Attracted To",
            options: ["Men", "Women", "Men & Women", "All Genders"],
            keyPath: \.attractedTo
        ) { value in
            try? await deps.profileManager.update(values: [.attractedTo: value])
        }
    }

    var body: some View {
        OptionEditView(field: attractedField)
    }
}

#Preview {
    optionFieldTesst()
}
