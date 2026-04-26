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
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: 35, height: 35)
                .glassIfAvailable(Circle())
                .contentShape(Circle())
                .foregroundStyle(Color.black)
        }
    }
}
//
//#Preview {
//    TabInfoButton(showScreen: true)
//}
