//
//  ProfileCard.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/08/2025.
//

import SwiftUI

struct ProfileCard : View {
    
    @Bindable var vm: MeetViewModel
    let profileInvite: ProfileModel
    @Binding var selectedProfile: ProfileModel?
    
    var body: some View {
        ZStack {
            VStack {
                if let image = profileInvite.image {
                    firstImage(image: image)
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedProfile = profileInvite
                            }
                        }
                    }
                }
                if let expiryTime = profileInvite.event?.inviteExpiryTime {
                    SimpleClockView(targetTime: expiryTime) {
                        guard let eventId = profileInvite.event?.id else {return}
                        Task { try await vm.updateEventStatus(eventId: eventId, status: .declinedTimePassed) }
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
