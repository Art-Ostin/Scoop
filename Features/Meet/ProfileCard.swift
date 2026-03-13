//
//  ProfileCard.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {
    
    @Bindable var vm: MeetViewModel
    @Binding var selectedProfile: UserProfile?
    
    let userProfile: UserProfile
    let image: UIImage
    let event: UserEvent?
    let size: CGFloat
    
    let onTap: () -> ()
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .defaultImage(size)
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
            .overlay(alignment: .bottomLeading) { cardOverlay }
    }
}


extension ProfileCard {
    
    private var cardOverlay: some View {
        HStack(alignment: .bottom) {
            infoSection
            Spacer()
            inviteButton
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
    }
    
    private var inviteButton: some View {
        Button {
            onTap()
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
                .fill(event != nil ? Color.appGreen : Color.accent)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
        )
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(userProfile.name)
                .font(.body(22, .bold))
            
            if let event {
                cardEventInfo(event: event)
            } else {
                cardProfileInfo
            }
        }
        .foregroundStyle(Color.white)
        .font(.body(14, .medium))
    }
    
    private var cardProfileInfo: some View {
        Text("\(userProfile.year) | \(userProfile.degree) | \(userProfile.hometown)")
            .font(.body(14, .medium))
    }
    
    @ViewBuilder
    private func cardEventInfo(event: UserEvent) -> some View {
        let dates = event.proposedTimes.dates.filter(\.stillAvailable).map(\.date)
        Group {
            if dates.count == 1 {
                Text(formatTime(date: dates.first))
            } else if dates.count == 2 {
                twoDateView(dates: dates)
            } else if dates.count == 3 {
                threeDateView(dates: dates)
            }
        }
        .overlay {eventInfoView(event: event)}
    }
    
    private func eventInfoView(event: UserEvent) -> some View {
        Text("\(event.type.description.emoji ?? "") \(event.type.description.label)")
            .font(.body(16, .medium))
            .offset(y: -28)
    }

    private func twoDateView(dates: [Date]) -> some View {
        Text(
            "\(formatTime(date: dates.first, withHour: false, wideWeek: false)) | " +
            "\(formatTime(date: dates[1], withHour: false, wideWeek: false)) · " +
            "\(formatTime(date: dates.first, onlyHour: true))"
        )
    }
    
    private func threeDateView(dates: [Date]) -> some View {
        let dayText = dates
            .map { formatTime(date: $0, withHour: false, wideWeek: false) }
            .joined(separator: ", ")
        
        return Text("\(dayText) · \(formatTime(date: dates[0], onlyHour: true))")
    }
}

//Logic dealing with the eventInfo
extension ProfileCard {
    
}

