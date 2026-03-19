//
//  ProfileInviteView.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct ProfileInviteView: View {
    
    @Bindable var ui: ProfileUIState
    let event: UserEvent
    var message: String  {
        (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            typeRow
            timeRow
            placeRow
        }
//        .overlay(alignment: .topTrailing) {
//            Text(event.type.description.emoji)
//                .font(.body(16, .medium))
//                .padding(.vertical)
//        }
    }
}


extension ProfileInviteView {
    private var typeRow: some View {
        
        HStack(spacing: 20) {
            Text(event.type.description.emoji)
                .font(.body(20, .medium))
            
            
            VStack(alignment: .leading, spacing: 4) {
                (
                    Text("\(event.type.title): ")
                        .font(.body(16, .medium))

                    +
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.gray)

                )
            }
        }
    }
    
    private var timeRow: some View {
        
        HStack(spacing: 24) {
            Image("MiniClockIcon")
                .scaleEffect(1.3)
            
            
            VStack(alignment: .leading, spacing: 4) {
            if let first = event.proposedTimes.firstAvailableDate {
                    Text(EventFormatting.fullDate(first))
                    .font(.body(16, .medium))

                    Text(EventFormatting.hourTime(first))
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
            }
        }
        
        
        
        
    }
    
    private var placeRow: some View {
        
        HStack(spacing: 24) {
            Image("MiniMapIcon")
                .scaleEffect(1.3)

            VStack {
                let location = event.location
                VStack(alignment: .leading) {
                    Text(location.name ?? "")
                        .font(.body(16, .medium))
                    Text(addressWithoutCountry(location.address))
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
            }
        }
    }
    private func addressWithoutCountry(_ address: String?) -> String {
        let parts = (address ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return parts.dropLast().joined(separator: ", ")
    }
    
}




//Type View

/*
 
 private func address() -> String {
     String([event.location.name, event.location.address]
             .compactMap { $0 }
             .joined(separator: ", ")
             .prefix(40)
     )
 }

 
 private var timeRow: some View {
     HStack(alignment: .center, spacing: 9) {
         Image("MiniClockIcon")
         
         if let first = event.proposedTimes.firstAvailableDate {
             HStack {
                 Text(EventFormatting.fullDateAndTime(first))
                     .font(.body(18, .regular))
                     .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.1))
                     .offset(y: 0.5)
             }
             Spacer()
             DropDownButton(isExpanded: $ui.showTimePopup, isAccept: true)
         }
     }
     .frame(maxWidth: .infinity, alignment: .leading)
 }

 
 
 
 
 private var placeRow: some View {
     HStack(spacing: 12) {
         Image("MiniMapIcon")
         
         Text(address())
             .font(.body(14, .regular))
             .foregroundStyle(Color(red: 0.11, green: 0.11, blue: 0.11))
             .underline()
             .lineLimit(1)
             .offset(y: 0.5)
     }
  }

 
 
 
 
 private var type2Row: some View {
     HStack {
         if message.isEmpty {
             typeWithNoMessage
         } else {
             typeWithMessage
         }
     }
 }
 
 @ViewBuilder private var typeWithNoMessage: some View {
     let d = event.type.description
     Text("\(d.emoji) \(d.label)")
         .font(.body(18))
 }
 
 private var typeWithMessage: some View {
     (inviteType + inviteMessage(trimmed: message))
         .lineSpacing(6)
         .contentShape(.rect)
         .frame(maxWidth: .infinity, alignment: .leading)
 }
 
 private var inviteType: Text {
     Text(verbatim: "\(event.type.description.emoji) \(event.type.description.label): ")
         .font(.body(16, .bold))
 }
 
 @ViewBuilder private func inviteMessage(trimmed: String) -> Text {
     Text(trimmed)
         .font(.body(12, .italic))
         .foregroundStyle(Color.grayText)
 }
 */
