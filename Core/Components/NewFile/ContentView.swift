//
//  ContentView.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct ContentView: View {
    
    @State private var selection: String?
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                DropDownTest(
                    hint: "Select",
                    options: [
                        "Youtube",
                        "Instagram",
                        "X",
                        "Snapchat",
                        "TikTok"
                    ],
                    selection: $selection)
            }
            .navigationTitle("Dropdown Picker ")
        }
    }
}

#Preview {
    ContentView()
}
