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
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Saved")
                .font(.body(14, .bold))
                .foregroundStyle(Color(red: 0.16, green: 0.65, blue: 0.27))
            
            Image("GreenTick")
                .offset(y: -2)
        }
        .padding(.top, topPadding)
        .padding(.horizontal, horizontalPadding)
    }
}
