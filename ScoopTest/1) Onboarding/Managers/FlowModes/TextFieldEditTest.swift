//
//  TextFieldEditTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct TextFieldEditTest: View {
    
    @Environment(\.appDependencies) private var dep
    
    
    var hometown: TextFieldField {
        TextFieldField(title: "Hometown", keyPath: \.hometown) { text in
            Task { try await dep.profileManager.update(values: [.hometown : text])}
        }
    }
    
    var body: some View {

        TextFieldEdit(field: hometown)
        
    }
}

#Preview {
    TextFieldEditTest()
}
