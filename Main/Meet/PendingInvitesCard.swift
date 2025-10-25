//
//  PendingInvitesView.swift
//  Scoop
//
//  Created by Art Ostin on 25/10/2025.
//

import SwiftUI

struct PendingInviteCard: View {
    
    let profile: ProfileModel
    
    @Binding var showInvitedProfile: ProfileModel?
    
    var body: some View {
        
        VStack {
            HStack(alignment: .top, spacing: 12) {
                
                if let image = profile.image {
                    Image(uiImage: image)
                        .resizable()
                        .defaultImage(132)
                    
                }
                
                VStack(alignment: .leading) {
                    Text(profile.profile.name)
                    
                    if let event = profile.event {
                        EventFormatter(time: event.time, type: event.type, message: event.message, place: event.place, size: 15)
                    }
                }
            }
            .padding([.top, .bottom, .trailing])
            .padding(.leading, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.background)
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.grayBackground, lineWidth: 1)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showInvitedProfile = profile
            }
            if let time = profile.event?.inviteExpiryTime {
                HStack(spacing: 4) {
                    Text("Auto-declined in:")
                    SimpleClockView(targetTime: time) {}
                }
                .font(.body(10, .regular))
                .foregroundColor(Color(red: 0.58, green: 0.58, blue: 0.58))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 36)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}
