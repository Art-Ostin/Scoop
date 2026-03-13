//
//  ProfileCard.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {
    
    @Bindable var vm: MeetViewModel
    @Binding var selectedProfile: UserProfile?
    
    let profile: PendingProfile
    let size: CGFloat
        
    var body: some View {
        Image(uiImage: profile.image ?? UIImage())
            .resizable()
            .defaultImage(size)
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
            .overlay(alignment: .bottomLeading) { cardOverlay }
    }
}

extension ProfileCard {
    
    private var cardOverlay: some View {
        HStack(alignment: .bottom) {
            infoSection
            Spacer()
            inviteButton
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
    }
    
    private var inviteButton: some View {
        Button {
            ui.selected
            onTap()
        } label: {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24)
        }
        .foregroundStyle(.white)
        .frame(width: 40, height: 40)
        .background(
            Circle()
                .fill(event != nil ? Color.appGreen : Color.accent)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
        )
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(userProfile.name)
                .font(.body(22, .bold))
            
            if let event {
                ProfileCardEventInfo(event: event)
            } else {
                cardProfileInfo
            }
        }
        .foregroundStyle(Color.white)
        .font(.body(14, .medium))
    }
    
    private var cardProfileInfo: some View {
        Text("\(userProfile.year) | \(userProfile.degree) | \(userProfile.hometown)")
            .font(.body(14, .medium))
    }
}
