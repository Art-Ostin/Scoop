//
//  MeetSuggestionView.swift
//  Scoop
//
//  Created by Art Ostin on 25/10/2025.
//

import SwiftUI

struct MeetSuggestionView: View {
    
    let user: UserProfile
    
    @Binding var showIdealMeet: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Text("My Meet suggestion")
                .font(.body(12, .italic))
                .foregroundStyle(Color.grayText)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let idealMeet = user.idealMeetUp {
                EventFormatter(time: idealMeet.time, type: idealMeet.type, message: idealMeet.message, place: idealMeet.place, size: 18)
            }
            Image("EditButton")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .stroke(24, color: .grayBackground)
        .containerShadow(color: .black.opacity(0.1), radius: 2, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
        .onTapGesture { showIdealMeet = true }
    }
}
