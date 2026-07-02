//
//  SaveIcon.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct SavedIcon: View {
    let topPadding: CGFloat
    let horizontalPadding: CGFloat
    let isSettings: Bool
    
    var body: some View {
        HStack(spacing: isSettings ? 2 : 12) {
            Text("Saved")
                .font(.body(isSettings ? 12 : 14, .bold))
                .foregroundStyle(Color(red: 0.16, green: 0.65, blue: 0.27))
            
            Image("GreenTick")
                .offset(y: -2)
                .scaleEffect(isSettings ? 0.6 : 1)
        }
        .padding(.top, topPadding)
        .padding(.horizontal, horizontalPadding)
    }
}
