//
//  optionFieldTesst.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct optionFieldTesst: View {
    
    @Environment(\.appDependencies) private var deps
    
    private var sexField: OptionField {
        OptionField(
            title: "Sex",
            options: ["Man", "Women", "Beyond Binary"],
            keyPath: \.sex
        ) { value in
            try? await deps.profileManager.update(values: [.sex: value])
        }
    }
    
    var body: some View {
        
    }
}

#Preview {
    optionFieldTesst()
}
