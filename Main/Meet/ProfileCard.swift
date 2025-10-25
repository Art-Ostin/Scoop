//
//  ProfileCard.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {
    
    @Bindable var vm: MeetViewModel
    let profile: ProfileModel
    @Binding var quickInvite: ProfileModel?
    let imageWidth: CGFloat
    var isInvite: Bool { profile.event != nil }
    
    var body: some View {
            VStack {
                ZStack {
                    if let image = profile.image {
                        Image(uiImage: image)
                            .resizable()
                            .defaultImage(imageWidth)
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
                            .overlay(alignment: .bottomLeading) {
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(profile.profile.name)
                                            .font(.body(22, .bold))
                                        Text("\(profile.profile.year) | \(profile.profile.degree) | \(profile.profile.hometown)")
                                            .font(.body(14, .medium))
                                    }
                                    .foregroundStyle(.white)
                                    
                                    Spacer()
                                    inviteButton
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal)
                            }
                    }
                }
                if let time = profile.event?.time {
                    HStack(spacing: 4) {
                        Text("Expires in:")
                        SimpleClockView(targetTime: time) {}
                    }
                    .font(.body(10, .regular))
                    .foregroundColor(Color(red: 0.58, green: 0.58, blue: 0.58))
                    .frame(width: (imageWidth.isFinite ? max(imageWidth - 24, 0) : 0), alignment: .topTrailing)
                    .padding(.top, 4)
                }
            }
    }
}



extension ProfileCard {
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Text(profile.profile.name)
                    .font(.body(24, .bold))
            }
            if let meet = profile.profile.idealMeetUp {
                let weekDay = meet.time.formatted(.dateTime.weekday(.wide))
                let hour = meet.time.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                
                HStack {
                    Text(weekDay + " " + hour)
                    
                    Text("|")
                        .foregroundStyle(Color.grayPlaceholder)
                    
                    Text(meet.type)
                }
                .font(.body(16, .regular))
                
            } else {
                HStack(spacing: 6) {
                    Text(profile.profile.hometown)
                    
                    Text("|")
                        .foregroundStyle(Color.grayPlaceholder)
                    
                    Text(profile.profile.degree)
                    
                    Text("|")
                        .foregroundStyle(Color.grayPlaceholder)
                    
                    Text(profile.profile.year)
                    
                }
                .font(.body(16, .regular))
            }
        }
    }
    
    private var inviteButton: some View {
        Button {
            quickInvite = profile
        } label: {
            Image("LetterIconProfile")
                .resizable()
                .scaledToFit()
                .frame(width: 24)
        }
        .foregroundStyle(.white)
        .frame(width: 40, height: 40)
        .background(
            Circle()
                .fill(isInvite ? Color.appGreen : Color.accent)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
        )
    }
}



/*
 .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
 
 
 HStack(alignment: .top) {
 infoSection
 Spacer()
 
 inviteButton
 }
 .padding(.horizontal, 18)
 .padding(.vertical, 12)
 .frame(width: 330)
 .background(
 UnevenRoundedRectangle(
 cornerRadii: .init(topLeading: 0, bottomLeading: 18, bottomTrailing: 18, topTrailing: 0),
 style: .continuous
 )
 .fill(.white)
 )
 .frame(maxHeight: .infinity, alignment: .bottom)
 */



/*
 VStack (spacing: 4) {
 HStack(spacing: 0) {
 if let image = profile.image { imageContainer(image: image, size: 170, shadow: 0) {}}
 
 profileInfo(profile: profile.profile)
 }
 .padding(6)
 .frame(width: 350, height: 175)
 .padding(6)
 .background (
 RoundedRectangle(cornerRadius: 18)
 .fill(Color.white)
 .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
 )
 .overlay(
 RoundedRectangle(cornerRadius: 18)
 .inset(by: 0.5)
 .stroke(Color(red: 0.93, green: 0.93, blue: 0.93), lineWidth: 1)
 )
 
 .onTapGesture { selectedProfile = profile }
 
 if let time = profile.event?.time {
 SimpleClockView(targetTime: time) {}
 .frame(width: 350, alignment: .topTrailing)
 }
 }
 }
 }
 
 
 
 
 
 extension ProfileCard {
 
 @ViewBuilder
 private func profileInfo (profile: UserProfile) -> some View {
 VStack (alignment: .leading, spacing: 20) {
 
 Text(profile.name)
 .font(.body(24, .medium))
 
 Group {
 if let meet = profile.idealMeetUp {
 
 let place = meet.place.name ?? " "
 let weekDay = meet.time.formatted(.dateTime.weekday(.wide))
 let hour = meet.time.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
 
 Text("\(weekDay), \(hour)  \(meet.type), ") +
 Text(place).foregroundStyle(isInvite ? Color.appGreen : Color.accentColor)
 
 
 } else {
 Text(profile.degree)
 }
 }
 .font(.body(16, .medium))
 }
 .padding(6)
 .lineSpacing(12)
 .frame(width: 170, height: 170, alignment: .topLeading)
 .padding(6)
 }
 }
 //                ForEach (profile.profile.nationality.prefix(2), id: \.self) {flag in
 //                    Text(flag)
 //                        .font(.body(16))
 //                }
 
 */

