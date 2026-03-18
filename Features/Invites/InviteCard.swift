//
//  InviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

struct InviteCard: View {
    
    @State var imageSize: CGFloat = 0
    
    let eventProfile: EventProfile
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            defaultImage(imageSize)
            
            ClearRectangle(size: 100)
            
        }
        .padding(8)                  // interior padding
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) {screenSize in
            imageSize = screenSize - (16 * 2)
        }
        .padding(.bottom, 12)        // extra interior bottom padding
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.background)
                .shadow(color: .black.opacity(0.25), radius: 1.8, x: 0, y: 3.6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(red: 0.96, green: 0.96, blue: 0.96), lineWidth: 1)
        )
        .padding(.horizontal, 28)    // outside spacing
    }
}
