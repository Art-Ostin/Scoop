//
//  NewInviteCard.swift
//  Scoop Test
//
//  Created by Art Ostin on 06/06/2026.
//

import SwiftUI

struct NewInviteCard: View {

    @State var imageSize: CGFloat = 100
    @Environment(ProfileMorphState.self) private var profileMorph: ProfileMorphState?
    let eventProfile: EventProfile
    var isMorphing: Bool = false
    @Binding var selectedProfile: UserProfile?
    let onRespond: () -> Void

    private static let imageRadii = RectangleCornerRadii(topLeading: 18, bottomLeading: 13, bottomTrailing: 13, topTrailing: 18)

    var body: some View {
        VStack(spacing: 20) {
            profileImage
            eventInfo
        }
        .modifier(InviteBackgroundCard())
        .getImageSize(imageSize: $imageSize, horizontalPadding: 6) //inner edge only; 16 outer lives in InvitesView
        .padding(.top, -10) //shift it closer to tile
    }
}

extension NewInviteCard {

    private var profileImage: some View {

        Image(uiImage: eventProfile.image ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: imageSize, height: imageSize + 12) //Have slightly long Image
            .clipShape(UnevenRoundedRectangle(cornerRadii: Self.imageRadii))
            .onTapGesture { openProfile() }
            //The profile morph flies a copy of this image, so the real one hides
            //for exactly the frames the copy is on screen.
            .profileMorphSource(id: eventProfile.profile.id, radii: Self.imageRadii)
    }

    private func openProfile() {
        guard selectedProfile == nil else { return }
        profileMorph?.beginOpen(id: eventProfile.profile.id, image: eventProfile.image)
        selectedProfile = eventProfile.profile
    }
    
    private var eventInfo: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                eventTitle
                eventType
            }
            eventTime
            eventPlace
        }
        .font(.body(18, .medium))
        .foregroundStyle(Color(white: 0.15))
        .overlay(alignment: .topTrailing) {
            InviteButton(isInviting: false, morphId: eventProfile.event.id, isInviteCard: true) { onRespond() }
                .opacity(isMorphing ? 0 : 1)
                .padding(.horizontal, -12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }
}
extension NewInviteCard {
        
    private var eventTitle: some View {
        Text("\(eventProfile.profile.name)'s Invite")
            .font(.body(22, .bold))
            .foregroundStyle(Color.black)
    }
    
    private var eventType: some View {
        let type = eventProfile.event.type
       return HStack(spacing: 18) {
            Text("\(type.emoji)")
               .frame(width: 20, alignment: .leading)
               .offset(x: type == .drink ?  -1 : 0)//Fine tuning due to image being slightly different
            Text("\(type.longTitle)")
        }
    }
    
    private var eventTime: some View {
        HStack(spacing: 18) {
            Image("MiniClockIcon")
                .scaleEffect(1.1, anchor: .bottom)
                .frame(width: 20, alignment: .leading)

            Text(formattedDay)
        }
    }
    
    private var eventPlace: some View {
        let location = eventProfile.event.location

        return HStack(alignment: .top, spacing: 18) {
            Image("MiniMapIcon")
                .scaleEffect(1.2, anchor: .bottom)
                .frame(width: 20, alignment: .leading)
                .offset(y: 5) // Fine Tuning
            
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
            .padding([.horizontal, .top], 6)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
            .background(Color.appCanvas)
            .clipShape(.rect(cornerRadius: 24))
            .customShadow(.card, strength: 1)
    }
}
