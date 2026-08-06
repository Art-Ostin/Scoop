//
//  InviteSlot.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

/*
 
 import SwiftUI
 struct InviteSlot: View {
     
     let vm: InvitesViewModel
     let eventProfile: EventProfile
     let onRespond: (ProfileResponse) -> Void
     
     @Binding var draft: RespondDraft
     @Binding var openInvite: EventProfile?
     
     @State private var profileTrigger = 0

     var body: some View {
         VStack(spacing: 72) {
             inviteCard
                 .onTapGesture { profileTrigger += 1 }
                 .padding(.top, -Spacing.md)
             
             CustomDivider().padding(.horizontal, 72)
             InviteInfo(event: eventProfile)
         }
     }
 }

 //InviteSlot
 extension InviteSlot {
     
     @ViewBuilder
     private var inviteCard: some View {
         if let image = eventProfile.image {
             InviteCard(image: image, name: eventProfile.profile.name, draft: $draft) {
                 openInvite = eventProfile
             }
         }
     }
 }
 */

