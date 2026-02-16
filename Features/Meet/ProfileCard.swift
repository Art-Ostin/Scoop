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
                                infoSection
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
        }
    }

extension ProfileCard {

    @ViewBuilder
    private var infoSection: some View {
        if let event = profile.event {
            let dates = event.proposedTimes.dates
                .filter(\.stillAvailable)
                .map(\.date)
            
            if !dates.isEmpty {
                eventInfoView(dates: dates)
                    .overlay(alignment: .topTrailing) {
                        (
                            Text(event.type.description.emoji ?? "")
                                .font(.body(15, .medium))
                            
                            +
                            Text(" \(event.type.description.label)")
                                .font(.body(16, .medium))
                        )
                        .offset(y: -28)

                    }
            } else {
                profileInfoView
            }
        } else {
            profileInfoView
        }
    }
    
    @ViewBuilder
    private func eventInfoView(dates: [Date]) -> some View {
        Group {
            if dates.count == 1 {
                Text(formatTime(date: dates.first))
            } else if dates.count == 2 {
                (
                    Text(formatTime(date: dates.first, withHour: false, wideWeek: false))
                    +
                    Text(" | ")
                    +
                    Text(formatTime(date: dates.last, withHour: false, wideWeek: false))
                    + Text ( " · ")
                    +
                    Text(formatTime(date: dates.first, onlyHour: true))
                )
            } else if dates.count == 3 {
                HStack(spacing: 0) {
                    ForEach(Array(dates.enumerated()), id: \.element) { index, date in
                        let suffix = (index < dates.count - 1) ? ", " : " · "
                        Text(formatTime(date: date, withHour: false, wideWeek: false) + suffix)
                    }
                    if let first = dates.first {
                        Text(formatTime(date: first, onlyHour: true))
                    }
                }
            }
        }
    }
        
    
    private var profileInfoView: some View {
        Text("\(profile.profile.year) | \(profile.profile.degree) | \(profile.profile.hometown)")
            .font(.body(14, .medium))
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


//Old Expiry time
/*
 if let time = profile.event. {
     HStack(spacing: 4) {
         Text("Expires in:")
         SimpleClockView(targetTime: time) {}
     }
     .font(.body(10, .regular))
     .foregroundColor(Color(red: 0.58, green: 0.58, blue: 0.58))
     .frame(maxWidth: .infinity, alignment: .trailing)
     .padding(.horizontal, 24)
 }
 */

/*
 
//            if let meet = profile.profile.idealMeetUp {
//                let weekDay = meet.time.formatted(.dateTime.weekday(.wide))
//                let hour = meet.time.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
//                HStack {
//                    Text(weekDay + " " + hour)
//                    Text("|")
//                        .foregroundStyle(Color.grayPlaceholder)
//
//                    Text(meet.type.description.label)
//                }
//                .font(.body(16, .regular))
//
//            } else {

 */
