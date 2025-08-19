//
//  ProfileCard.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/08/2025.
//

import SwiftUI

struct ProfileCard : View {
    
    @Binding var vm: MeetViewModel
    let profileInvite: ProfileInvite
    @Binding var selectedProfile: ProfileInvite?
    
    var body: some View {
        ZStack {
            if let image = profileInvite.image {
                firstImage(image: image)
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedProfile = profileInvite
                        }
                    }
                }
            }
        }
    }
    private func firstImage(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 320, height: 422)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
    }
}
