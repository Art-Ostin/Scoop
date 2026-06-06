//
//  NewInviteCard.swift
//  Scoop Test
//
//  Created by Art Ostin on 06/06/2026.
//

import SwiftUI

struct NewInviteCard: View {
    
    @State var imageSize: CGFloat = 100
    let eventProfile: EventProfile
    
    var body: some View {
        VStack(spacing: 24) {
            profileImage
            eventInfo
        }
        .modifier(InviteBackgroundCard())
        .getImageSize(imageSize: $imageSize, horizontalPadding: 8) //inner edge only; 16 outer lives in InvitesView
    }
}

extension NewInviteCard {

    private var profileImage: some View {
        Image(uiImage: eventProfile.image ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: imageSize, height: imageSize + 25) //Have slightly long Image
            .clipShape(UnevenRoundedRectangle(cornerRadii: .init( topLeading: 18, bottomLeading: 13, bottomTrailing: 13, topTrailing: 18)))
    }
    
    private var eventInfo: some View {
        VStack(alignment: .leading, spacing: 22) {
            eventTitle
            eventType
            eventTime
            eventPlace
        }
        .font(.body(17, .medium))
        .foregroundStyle(Color(white: 0.15))
        .overlay(alignment: .topTrailing) {
            InviteButton(isInviting: false, morphId: "test") {}
        }
        .padding(.horizontal, 8) //Extra padding for this
    }
}
extension NewInviteCard {
        
    private var eventTitle: some View {
        Text("\(eventProfile.profile.name) Invite")
            .font(.body(20, .bold))
            .foregroundStyle(Color.black)
    }
    
    private var eventType: some View {
        let type = eventProfile.event.type
       return HStack(spacing: 12){
            Text("\(type.emoji)")
            Text("\(type.longTitle)")
        }
    }
    
    private var eventTime: some View {
        HStack(spacing: 13) {
            Image("MiniClockIcon")
                .scaleEffect(1.1)
            
            Text(formattedDay)
        }
    }
    
    private var eventPlace: some View {
        let location = eventProfile.event.location

        return HStack(spacing: 16) {
            Image("MiniMapIcon")
                .scaleEffect(1.1)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(location.name ?? "")
                
                Text(FormatEvent.addressWithoutCountry(location.address))
                    .font(.body(12, .regular))
                    .foregroundStyle(Color(white: 0.55))
            }
        }

    }
    
    var formattedDay: String {
        if let firstDay = eventProfile.event.proposedTimes.firstAvailableDate {
            let day  = firstDay.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())  // Thursday, Sep 23
            let time = firstDay.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))  // 22:30
            return "\(day) · \(time)"
        } else {
            return "Invite Time Expired"
        }
    }
}

struct InviteBackgroundCard: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .padding([.horizontal, .top], 8)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
            .background(Color.appCanvas)
            .clipShape(.rect(cornerRadius: 24))
            .customShadow(.card, strength: 2)
    }
}
