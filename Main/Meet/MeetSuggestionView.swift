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
        VStack {
            
            Text("My Meet suggestion")
                .font(.body(12, .medium))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 36)
            
            VStack {
                
                if let idealMeet = user.idealMeetUp {
                    EventFormatter(time: idealMeet.time, type: idealMeet.type, message: idealMeet.message, place: idealMeet.place, size: 18)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .padding(.bottom, 12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.clear)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.grayBackground, lineWidth: 1)
            )
            .overlay(alignment: .bottomTrailing) {            // edit button
                Image("EditButton").padding(12)
            }
            .contentShape(RoundedRectangle(cornerRadius: 24))
            .onTapGesture { showIdealMeet = true }
            .padding(.horizontal, 24)
        }
    }
}

