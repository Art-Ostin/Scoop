//
//  ProfileCard.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {
    
    @Binding var openProfile: UserProfile?
    @Binding var quickInvite: UserProfile?
    
    let profile: PendingProfile
    let size: CGFloat
        
    var body: some View {
        Image(uiImage: profile.image)
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
            quickInvite = profile.profile
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
                .fill(Color.accent)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
        )
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let p = profile.profile
            Text(p.name)
                .font(.body(22, .bold))
            
            Text("\(p.year) | \(p.degree) | \(p.hometown)")
                .font(.body(14, .medium))
        }
        .foregroundStyle(Color.white)
        .font(.body(14, .medium))
    }
}
