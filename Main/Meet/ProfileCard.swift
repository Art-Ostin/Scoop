//
//  ProfileCard.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {
    let profile: ProfileModel
    
    let size: CGFloat
    
    @Bindable var vm: MeetViewModel
    @Binding var quickInvite: ProfileModel?
    @Binding var selectedProfile: ProfileModel?
    var isInvite: Bool { profile.event != nil }
    
    var body: some View {
        VStack {
            if let image = profile.image {
                Image(uiImage: image)
                    .resizable()
                    .defaultImage(size)
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
//                    .onTapGesture {selectedProfile = profile}
            }
            if let time = profile.event?.time {
                HStack(spacing: 4) {
                    Text("Expires in:")
                    SimpleClockView(targetTime: time) {}
                }
                .font(.body(10, .regular))
                .foregroundColor(Color(red: 0.58, green: 0.58, blue: 0.58))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 24)
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

