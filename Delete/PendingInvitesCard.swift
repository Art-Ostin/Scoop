//
//  PendingInvitesView.swift
//  Scoop
//
//  Created by Art Ostin on 25/10/2025.
//

import SwiftUI


/*
 
 struct PastInviteView: View {
     @Bindable var vm: InviteViewModel
     @Bindable var ui: MeetUIState

     var body: some View {
         NavigationStack {
             ScrollView(.vertical) {
                 LazyVStack(spacing: 48) {
                     ForEach(vm.pendingInvites) { profile in
                         
                         
                         PendingInviteCard(
                             profile: profileModel,
                             showPendingInvites: $ui.showPendingInvites,
                             openPastInvites: $ui.openPastInvites
                         )
                     }
                 }
             }
             .navigationTitle("Your Pending Invites")
             .navigationBarTitleDisplayMode(.inline)
         }
         .presentationDetents([.medium, .large])
         .presentationDragIndicator(.visible)
     }
 }





 struct PendingInviteCard: View {
     
     let eventProfile: EventProfile
     
     @Binding var showPendingInvites: Bool
     @Binding var openPastInvites: Bool
     
     var body: some View {
         if let image = eventProfile.image  {
             HStack(alignment: .top, spacing: 12)  {
                 Image(uiImage: image)
                     .resizable()
                     .defaultImage(132)
                 
                 VStack(alignment: .leading, spacing: 4) {
                     let event = eventProfile.event
                     Text(eventProfile.profile.name)
                     if let time = event.proposedTimes.dates.first?.date {
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


 
 */
