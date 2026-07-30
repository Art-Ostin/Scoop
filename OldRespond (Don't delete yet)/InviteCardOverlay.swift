//
//  InviteCardOverlay.swift
//  Scoop Test
//
//  Created by Art Ostin on 30/07/2026.
//
 
/*
 
 
 struct InviteCardOverlay<TimeRow: View>: View {
     let name: String
     let timeOpen: Bool
     let event: InviteSummary
     @ViewBuilder var timeRow: TimeRow
     
     let openInvite: () -> ()

         
     var body: some View {
         
         VStack(alignment: .leading, spacing: 24) {
             InviteName(name: name, isCard: true)
                 .opacityPop(visible: !timeOpen)
             
             TimeAndPlaceRows(place: event.place, hide: !timeOpen) {
                 timeRow
             }
         }
         .overlay(alignment: .topTrailing) { typeButton}
         .frame(maxWidth: .infinity, maxHeight: .infinity,  alignment: .bottomLeading)
         .overlay(alignment: .bottomTrailing) {InviteButton {openInvite()} }
         .padding(24)
         .padding(.bottom, 5)
     }
 }

 extension InviteCardOverlay {
     
     private var typeButton: some View {
             HStack {
                 Image("DrinkIcon")
                 
                 Text(event.type.longTitle) //"Grab Drinks"
                     .font(.system(size: 15, weight: .bold))
                     .foregroundStyle(Color.white)
             }
             .padding(.vertical, 6)
             .padding(.horizontal, 10)
             .stroke(12, lineWidth: 1, color: .white.opacity(0.6))
             .scaleEffect(0.8, anchor: .bottomTrailing)
             .offset(y: -1.5)
             .opacityPop(visible: !timeOpen)
     }
 }

 */
