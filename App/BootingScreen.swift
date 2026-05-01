//
//  BootingScreen.swift
//  Scoop
//
//  Created by Art Ostin on 01/05/2026.
//

import SwiftUI

struct BootingScreen: View {
    var body: some View {
        ZStack {
            Color.accent.ignoresSafeArea()
            
            Text("Loading")
                .font(.custom("SFProRounded-Bold", size: 32))
                .foregroundStyle(Color.white)
        }
    }
}

#Preview {
    BootingScreen()
}
