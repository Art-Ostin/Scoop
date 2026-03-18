//
//  InviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

struct InviteCard: View {
    
    @State private var imageSize: CGFloat = 0
    
    private let contentPadding: CGFloat = 8
    
    
    let eventProfile: EventProfile
    @Bindable var vm: RespondViewModel
    
    var body: some View {
        
        VStack(spacing: 20) {

            Image(uiImage: eventProfile.image ?? UIImage())
                .resizable()
                .defaultImage(imageSize)
                        
            InviteCardInfo(image: nil, name: eventProfile.profile.name, event: eventProfile.event, vm: vm)
        }
        .padding(contentPadding)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) { cardWidth in
             imageSize = max(cardWidth - (contentPadding * 2), 0)
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
