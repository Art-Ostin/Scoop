//
//  InviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

/*
 
 import SwiftUI

 struct InviteCard: View {
     
     @Bindable var vm: RespondViewModel
     @Bindable var ui: InvitesUIState
     
     @State var showMessageScreen = false
     @State var showTimePopup = false
     @State var imageSize: CGFloat = 0
     @State var nameRect: CGRect = .zero

     
     let eventProfile: EventProfile
     let contentPadding: CGFloat = 6

     var dayCount: Int { vm.respondDraft.newTime.proposedTimes.dates.count}
     var image: UIImage {eventProfile.image ?? UIImage()}
     
     
     let openProfile: (UserProfile) -> ()
     let onDecline: (String) -> ()

     var body: some View {
         Image(uiImage: image)
             .resizable()
             .scaledToFill()
             .frame(width: max(imageSize, 0), height: max(imageSize + 100, 0))
             .clipShape(.rect(cornerRadius: 24))
             .contentShape(Rectangle())
             .onTapGesture {openProfile(eventProfile.profile)}
             .padding(.horizontal, contentPadding)
     }
 }

 extension InviteCard {
     
     /*
      VStack(spacing: 0) {
          profileImage
          inviteEventSection
      }
      .modifier(InviteCardStyle())
      .sheet(isPresented: $showMessageScreen) {addMessageView}
      .onTapGesture {if ui.showTimePopup {ui.showTimePopup = false}}
      .getImageSize(imageSize: $imageSize, horizontalPadding: contentPadding)

      */
     
     private var inviteEventSection: some View {
         CardEventContainer(
             vm: vm,
             invitesUI: ui,
             showMessageScreen: $showMessageScreen) {onDecline($0)}
     }
         
     private var addMessageView: some View {
         AddMessageView(
             message: $vm.respondDraft.respondMessage,
             isRespondMessage: true,
             eventType: .constant(.drink)
         )
         .presentationBackgroundInteraction(.enabled)
     }
     
     private var profileImage: some View {
         Image(uiImage: eventProfile.image ?? UIImage())
             .defaultImage(imageSize)
             .contentShape(Rectangle())
             .onTapGesture {openProfile(eventProfile.profile)}
             .padding(.horizontal, contentPadding)
             .opacity(ui.showTimePopup ? 0.2 : 1)
     }
 }

 struct InviteCardStyle: ViewModifier {
     func body(content: Content) -> some View {
         content
             .padding(.vertical, 8)
             .frame(maxWidth: .infinity)
             .background(Color.appCanvas, in: .rect(cornerRadius: 22))
             .customShadow(.card, strength: 2)
     }
 }

 */
