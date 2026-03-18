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

            Image(uiImage: eventProfile.image ?? UIImage())
                .resizable()
                .defaultImage(imageSize)
            ClearRectangle(size: 100)
        }
        .padding(8)                  // interior padding
        .padding(.bottom, 12)        // extra interior bottom padding
        .frame(maxWidth: .infinity)
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) {screenSize in
            imageSize = screenSize
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.background)
                .shadow(color: .black.opacity(0.25), radius: 1.8, x: 0, y: 3.6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(red: 0.96, green: 0.96, blue: 0.96), lineWidth: 1)
        )
    }
}
