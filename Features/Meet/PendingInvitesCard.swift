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
                    if let event = profile.event, let time = event.acceptedTime  {
                        EventFormatter(time: time, type: event.type, message: event.message, place: event.location, size: 15)
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
            .padding(.horizontal, 24)
        }
    }
}

