//
//  Screen Test.swift
//  Scoop
//
//  Created by Art Ostin on 21/01/2026.
//

import SwiftUI

struct Screen_Test: View {    
    var body: some View {
        Image("ChatIcon")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .font(.body(17, .bold))
            .padding()
            .background (
                Circle()
                    .foregroundStyle(Color.background)
                    .stroke(100, lineWidth: 1.5, color: .black)
            )
            .defaultShadow()
    }
}

#Preview {
    Screen_Test()
}
