//
//  InfoButton.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct TabInfoButton: View {
    @Binding var showScreen: Bool
    var body: some View {
        Button {
            showScreen = true
        } label: {
            Image(systemName: "info.circle")
                .padding(6)
                .foregroundStyle(.black)
                .glassIfAvailable(Circle())
                .padding(.horizontal)
                .padding()
        }
    }
}
//
//#Preview {
//    TabInfoButton(showScreen: true)
//}
