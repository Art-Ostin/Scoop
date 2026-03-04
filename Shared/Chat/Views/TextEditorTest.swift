//
//  TextEditorTest.swift
//  Scoop
//
//  Created by Art Ostin on 03/03/2026.
//

import SwiftUI

struct TextEditorTest: View {
    var body: some View {
        Menu {
            Text("Action 1")
            
            Text("Action 2")
            
            Text("Action 3")
        } label: {
            HStack {
                Text("Tap Me")
                Image(systemName: "chevron.down")
            }
        }

        
    }
}

#Preview {
    TextEditorTest()
}
