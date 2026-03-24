//
//  AcceptInviteView.swift
//  Scoop
//
//  Created by Art Ostin on 15/02/2026.
//

/*
 
 import SwiftUI

 struct AcceptInviteView: View {
     
     @Bindable var ui: ProfileUIState
     
     let profile: UserProfile
     let event: UserEvent
     let image: UIImage?
     
     let onAccept: (UserEvent) -> ()
     let onDecline: (UserEvent) -> ()
     
     @State var showInfoScreen: Bool = false
     @Bindable var vm: RespondViewModel
     
     
     var body: some View {
         ZStack {
             CustomScreenCover { ui.showInfoSheet = false }
             VStack(alignment: .center, spacing: 24) {
                 popupTitle
                 VStack(spacing: 16) {
                     Text(FormatEvent.dayAndTime(accept ))
                     eventMessage
                     typeAndPlace
                 }
                 ActionButton(text: "Accept", isInvite: true, cornerRadius: 16) { onAccept(event) }
             }
             .padding(22)
             .padding(.bottom, 8)
             .frame(maxWidth: .infinity).padding(.horizontal, 48)
             .background(popupBackground)
             .stroke(24, lineWidth: 1, color: Color.grayPlaceholder)
             .overlay(alignment: .topTrailing) {tabInfoButton}
             .offset(y: 12)
         }
         .sheet(isPresented: $showInfoScreen) {Text("Info Screen")}
         .overlay(alignment: .topLeading) { declineButton}
         .hideTabBar()
     }
 }

 extension AcceptInviteView {
     
     private var popupTitle: some View {
         HStack(spacing: 8) {
             if let image {
                 CirclePhoto(image: image, showShadow: false, height: 30)
             }
             
             Text("Meet \(profile.name)")
                 .font(.body(22, .bold))
         }
     }
     
     @ViewBuilder
     private var inviteTime: some View {
         let day = EventFormatting.expandedDate(event.proposedTimes.dates.first?.date ?? Date())
         let hour = EventFormatting.hourTime(event.proposedTimes.dates.first?.date ?? Date())
         
         Text("\(day) · \(hour)")
             .font(.body(20, .medium))
     }
         
     private var typeAndPlace: some View {
         HStack(spacing: 8) {
             Text("\(event.type.description.emoji)  \(event.type.description.label) ")
                 .font(.body(16, .medium))
             
             Button {
                 MapsRouter.openGoogleMaps(item: event.location.mapItem, withDirections: false)
             } label: {
                 Text(event.location.name ?? "Location")
                     .font(.body(20, .bold))
                     .foregroundStyle(Color.appGreen)
             }
         }
     }
     
     @ViewBuilder
     private var eventMessage: some View {
         if let message = event.message, !message.isEmpty {
             Text(message)
                 .font(.body(14, .italic))
                 .lineSpacing(5)
                 .multilineTextAlignment(.center)
                 .foregroundStyle(Color.grayText)
         }
     }
     
     private var tabInfoButton: some View {
         TabInfoButton(showScreen: $ui.showInfoSheet)
             .scaleEffect(0.9)
             .offset(x: -12, y: -48)
     }
     
     private var popupBackground: some View {
         RoundedRectangle(cornerRadius: 24)
             .foregroundStyle(Color.background)
             .shadow(color: .appGreen.opacity(0.15), radius: 4, y: 2)
     }
     
     private var declineButton: some View {
         MinimalistButton(text: "Decline") {
             onDecline(event)
         }
         .padding(.top, 36)
         .padding(.horizontal, 20)
     }
 }

 */

