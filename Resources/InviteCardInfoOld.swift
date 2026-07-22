//
//  InviteCardEventInfo.swift
//  Scoop
//
//  Created by Art Ostin on 22/06/2026.
//

/*
 
 import SwiftUI

 struct InviteCardInfoOld: View {
     
     //Injected
     @Environment(\.timeCustomMenuDismiss) private var timeMenuDismiss
     @Binding var draft: RespondDraft
     let eventProfile: EventProfile
     let onRespond: () -> ()
     
     var body: some View {
         VStack(alignment: .leading, spacing: Spacing.lg) {
             eventTypeLine
             eventTimeLine
             eventPlaceLine
         }
         .font(.body(17, .bold))
         .modifier(InviteCardInfoBackground())
         .overlay(alignment: .bottomTrailing) {inviteButton}
         .overlay(alignment: .topTrailing) { infoButton}
     }
 }

 //Different Views
 extension InviteCardInfoOld {
     
     private var eventTypeLine: some View {
         HStack(spacing: Spacing.sm) {
             Text(eventProfile.event.type.emoji)
                 .font(.body(14))
                 .frame(width: 20, alignment: .leading)
             
             Text(eventProfile.event.type.longTitle)
         }
     }
     
     private var eventPlaceLine: some View {
         HStack(spacing: Spacing.sm) {
             Image("MiniMapIcon")
                 .scaleEffect(1.2, anchor: .center)
                 .frame(width: 20, alignment: .leading)

             Text("Barbossa Montreal") //eventProfile.event.location.name ?? ""
                 .foregroundStyle(Color.successGreen)
                 .frame(maxWidth: .infinity, alignment: .leading)
                 .padding(.trailing, Spacing.lg)
         }
     }
     
     private var eventTimeLine: some View {
         RespondTimeRow(draft: $draft, rowHasIcon: true)
     }
         
     private var infoButton: some View {
         SmallInfoIcon(size: 12, colour: Color.textPlaceholder)
             .padding()
             .padding(.trailing, Spacing.xs)
     }
     
     private var inviteButton: some View {
         InviteButton(isInviting: false, isInviteCard: true) {
             onRespond()
         }
         .padding(Spacing.sm)
     }
 }

 struct InviteCardInfoBackground: ViewModifier {
     
     func body(content: Content) -> some View {
         content
             .padding(Spacing.md)
             .padding(.vertical, Spacing.xs)
             .frame(maxWidth: .infinity, alignment: .leading)
             .background(Color.appCanvas, in: .rect(cornerRadius: CornerRadius.concentric(in: CornerRadius.image, inset: 12)))
     }
 }

 */
