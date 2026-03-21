//
//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 21/03/2026.
//

import SwiftUI

struct RespondDetailsCard: View {
    
    let event: UserEvent
    @Binding var isFlipped: Bool

    let image: UIImage
    
    var openingMessage: String {
        event.proposedTimes.availableDates().count > 0
        ? "Select a time \(event.otherUserName) proposed, or suggest a new time"
        : "\(event.otherUserName)'s proposed times have expired. So, first, select a time you're availble"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            inviteDetailsTitle
            
            Text(openingMessage)
                .font(.body(16, .italic))
                .foregroundStyle(Color.grayText)
            
            Text("When you've accepted their invite you can begin messaging")
                .font(.body(16, .bold))
            
            Text(event.type.howItWorks(userEvent: event))
                .font(.body(16, .medium))
        }
        .lineSpacing(8)
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(CardBackground())
        .padding(.horizontal, 24)
    }
}

extension RespondDetailsCard {
    
    private var Title: some View {
        Text("How it Works")
            .font(.body(12, .bold))
            .tracking(1.2)
            .foregroundStyle(Color.grayText)
    }
    
    @ViewBuilder
    private var inviteDetailsTitle: some View {
        HStack {
            Text ("\(event.type.description.emoji) \(event.type.description.label)")
                .font(.custom("SFProRounded-Medium", size: 20))
            
            Spacer()
            backToEvent
        }
    }
    
    private var backToEvent: some View {
        Button {
            isFlipped.toggle()
        } label: {
            HStack(spacing: 8) {
                CirclePhoto(image: image, showShadow: false, height: 25)
                Text("Event")
                    .font(.custom("SFProRounded-Bold", size: 16))
                    .foregroundStyle(Color.appGreen)
                    .contentShape(.rect)
            }
            .background (
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.background)
                        .shadow(color: .appGreen.opacity(0.1), radius: 5, x: 0, y: 4)

                    RoundedRectangle(cornerRadius: 30)
                        .inset(by: 0.5)
                        .stroke(Color.grayBackground, lineWidth: 0.5)
                }
            )
        }
    }
}

/*
 
 private var inviteDetailsTitle: some View {
     
     HStack {
         HStack(spacing: 8) {
            Image(systemName: "info.circle")
                 .font(.body(20, .regular))
                  .foregroundStyle(Color.grayText)
             
             HStack(spacing: 2) {
                 Text("How it works: ")
                 
                 +
                 
                 Text("\(event.type.description.label)")
                     .font(.custom("SFProRounded-Bold", size: 20))
                 
                 Text("\(event.type.description.emoji)")
                     .font(.body(20))
             }
         }
         
         Spacer()
         
         backToEvent
     }
 }

 
 
 Text("\(event.type.description.emoji)  \(event.type.description.label)")
     .font(.custom("SFProRounded-Bold", size: 24))
 
 Spacer()
 
 Button {
     isFlipped = false
 } label: {
     Text("Event")
         .foregroundStyle(Color.appGreen)
         .font(.body(16, .bold))
 }
}

 */
