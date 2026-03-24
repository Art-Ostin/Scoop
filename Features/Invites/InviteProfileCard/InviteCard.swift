//
//  InviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

struct InviteCard: View {
    
    @Bindable var vm: RespondViewModel
    @Bindable var ui: InvitesUIState
    let eventProfile: EventProfile
    
    let openProfile: (UserProfile) -> ()
    
    @State private var imageSize: CGFloat = 0
    private let contentPadding: CGFloat = 8
    
    var body: some View {
        VStack(spacing: 20) {
            profileImage

            InviteCardInfo(vm: vm, image: nil, name: eventProfile.profile.name, eventProfile: eventProfile, showTimePopup: $ui.showTimePopup)
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
        .stroke(22, lineWidth: 1, color: Color(red: 0.96, green: 0.96, blue: 0.96))
        
        .onTapGesture {
            if ui.showTimePopup {
                withAnimation(.easeInOut(duration: 0.15)) {
                    ui.showTimePopup = false
                }
            }
        }
    }
}

extension InviteCard {
    
    
    private var profileImage: some View {
        Image(uiImage: eventProfile.image ?? UIImage())
            .resizable()
            .defaultImage(imageSize)
            .opacity(ui.showTimePopup ? 0.3 : 1)
            .contentShape(Rectangle())
            .onTapGesture {openProfile(eventProfile.profile)}
    }
    
    
    
}
