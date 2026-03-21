//
//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//
import SwiftUI

struct RespondCard: View {
    
    @Bindable var ui: ProfileUIState
    @Binding var isFlipped: Bool
    
    let event: UserEvent
    let image: UIImage
    let name: String
    
    let onAccept: (UserEvent) -> ()
    let onDecline: (UserEvent) -> ()
    
    var message: String  {
        (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 20) { //Camera pushes it down more, this makes it more natural
                titleRow
                timeRow
            }
            placeRow
            actionSection
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(CardBackground())
        .padding(.horizontal, 24)
        .offset(y: 32)
    }
}

extension RespondCard {
    
    private var titleRow: some View {
            HStack(spacing: 8) {
                CirclePhoto(image: image, showShadow: false, height: 30)
                Text("Meet Genevieve")
                    .font(.custom("SFProRounded-Bold", size: 24))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
                HStack(spacing: 0) {
                    Text("\(event.type.description.emoji) Double Date")
                        .font(.body(16, .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .allowsTightening(true)
                    
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.grayText).opacity(0.6)
                        .font(.body(14, .medium))
                        .offset(y: -12)
                }
                .frame(width: 120, alignment: .trailing)
            }
            .padding(.trailing, -12)
    }
    
    
    private var timeRow: some View {
        
        HStack(spacing: 24) {
            Image("MiniClockIcon")
                .scaleEffect(1.3)
            
            VStack(alignment: .leading, spacing: 4) {
                if let first = event.proposedTimes.firstAvailableDate {
                    if let message = event.message {
                        Text(EventFormatting.fullDateAndTime(first))
                            .font(.body(16, .medium))
                        
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    } else {
                        Text(EventFormatting.fullDate(first, wideMonth: true))

                        Text(EventFormatting.hourTime(first))
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }
    
    private var placeRow: some View {
        HStack(spacing: 24) {
            Image("MiniMapIcon")
                .scaleEffect(1.3)
                .foregroundStyle(Color.appGreen)
            
            VStack {
                let location = event.location
                VStack(alignment: .leading) {
                    Text(location.name ?? "")
                        .font(.body(16, .medium))
                    Text(EventFormatting.addressWithoutCountry(location.address))
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .underline()
                        .lineLimit(1)
                }
            }
        }
    }

    private var actionSection: some View {
        HStack {
            DeclineButton {onDecline(event) }
            Spacer()
            AcceptButton {onAccept(event)}
        }
    }
}




/*
 VStack(alignment: .leading, spacing: 4) {
     if let first = event.proposedTimes.firstAvailableDate {
         if let message = event.message {
             Text(EventFormatting.fullDateAndTime(first))
                 .font(.body(16, .medium))
             
             Text(message)
                 .font(.footnote)
                 .foregroundStyle(.gray)
         } else {
             Text(EventFormatting.fullDate(first, wideMonth: true))
             
             Text(EventFormatting.hourTime(first))
                 .font(.footnote)
                 .foregroundStyle(.gray)
         }
     }
 }

 
 private var newEventInfoButton: some View {
     Group {
         Text("\(event.type.description.emoji) Double Date ") //\(event.type.description.label)
             .font(.body(16, .medium))
         +
         Text(Image(systemName: "info.circle"))
             .foregroundStyle(Color.grayText.opacity(0.5))
             .font(.body(14, .medium))
     }
 }
 
 
 private var eventInfoButton: some View {
     Button {
         isFlipped = true
     } label: {
         HStack(alignment: .center, spacing: 2) {
             Text("\(event.type.description.emoji)")
                 .font(.body(16, .medium))
             Text("Double Date") //\(event.type.title)]
                 .font(.body(16, .medium))
                 .frame(width: 80, alignment: .leading)
             Image(systemName: "info.circle")
                 .foregroundStyle(Color.grayText).opacity(0.6)
                 .font(.body(14, .medium))
         }
     }
 }
 private var typeRow: some View {
     
     HStack(spacing: 24) {
         Image("CupContainer")
         VStack(alignment: .leading, spacing: 4) {
             Text("Double Date")
                 .font(.body(16, .medium))
             
         
             Text(message)
                 .font(.footnote)
                 .foregroundStyle(.gray)
         }
     }
 }


 
 */
