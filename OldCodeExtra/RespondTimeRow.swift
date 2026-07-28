//
//  NewRespondTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 23/06/2026.
//

/*
 
 import SwiftUI

 struct RespondTimeRow: View {
     
     //Injected
     @Binding var draft: RespondDraft
     var rowHasIcon = false

     var body: some View {
         TimeCustomMenu {
             RespondTimePopup(draft: $draft)
         } label: {
             originalRowLabel
         }
     }
 }

 //Original Invite Row
 extension RespondTimeRow {
     
     private var originalRowLabel: some View {
         HStack(spacing: Spacing.sm) {
             if rowHasIcon {
                 clockIcon
                     .frame(width: 20)
             }
             dayDropDownRow
         }
     }
     
     private var dayDropDownRow: some View {
         HStack(spacing: Spacing.sm) {
             Text(formattedDay)
                 .font(.body(17, .bold))

             DropDownButton(isOpen: false, isAccept: true)
         }
     }
     
     private var formattedDay: String {
         if let selectedDay = draft.originalInvite.selectedDay {
             let day  = selectedDay.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())  // Thursday, Sep 23
             let time = selectedDay.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))  // 22:30
             return "\(day) · \(time)"
         } else {
             return "Invite Time Expired"
         }
     }
     
     private var clockIcon: some View {
         Image("MiniClockIcon")
             .scaleEffect(1.1, anchor: .bottom)
             .frame(width: 20, alignment: .leading)
     }
 }
 */

