//
//  PendingInvitesView.swift
//  Scoop
//
//  Created by Art Ostin on 25/10/2025.
//

import SwiftUI

struct PendingInviteCard: View {
    let profile: ProfileModel
    
    @Binding var showPendingInvites: Bool
    @Binding var openPastInvites: Bool
    
    var body: some View {
        if let image = profile.image  {
            HStack(alignment: .top, spacing: 12)  {
                Image(uiImage: image)
                    .resizable()
                    .defaultImage(132)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.profile.name)
                    if let event = profile.event {
                        EventFormatter(time: event.time, type: event.type, message: event.message, place: event.place, size: 15)
                    }
                }
            }
            .padding([.vertical, .trailing])
            .padding(.leading, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.background)
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
                    .stroke(18, lineWidth: 1, color: .grayBackground)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(nil) {
                    showPendingInvites = false
                    Task {
                        try? await Task.sleep(for: .seconds(0.5))
                        openPastInvites = true
                    }
                }
            }
            .overlay {
                if let time = profile.event?.inviteExpiryTime {
                    HStack(spacing: 4) {
                        Text("Auto-declined in:")
                        SimpleClockView(targetTime: time) {}
                    }
                    .font(.body(10, .regular))
                    .foregroundColor(Color(red: 0.58, green: 0.58, blue: 0.58))
                    .padding(.horizontal, 36)
                    .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
