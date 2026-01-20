//
//  DetailsInfo.swift
//  Scoop
//
//  Created by Art Ostin on 02/11/2025.
//

import SwiftUI
import SwiftUIFlowLayout




struct UserKeyInfo: View {
    let p : UserProfile
    var body : some View {
        HStack(alignment: .center) {
                InfoItem(image: "Year", info: p.year)
                Spacer()
                InfoItem(image: "Height", info: ("193cm"))
                Spacer()
                InfoItem(image: "House", info: p.hometown)
            }
            Divider().background(Color.grayPlaceholder)
            InfoItem(image: "ScholarStyle", info: p.degree)
            Divider().background(Color.grayPlaceholder)
            InfoItem(image: "magnifyingglass", info: p.lookingFor)
    }
}

struct UserInterests: View {
    let p: UserProfile
    let interestScale: CGFloat
    
    var body: some View {
        FlowLayout(mode: .vstack, items: p.interests, itemSpacing: 6) { text in
            Text(text)
                .padding(.horizontal, 8 * interestScale)
                .padding(.vertical, 10 * interestScale)
                .font(.body(16 * interestScale))
                .stroke(12 * interestScale, color: Color(red: 0.90, green: 0.90, blue: 0.90))
                .stroke(12, color: Color(red: 0.90, green: 0.90, blue: 0.90))
                .measure(key: FlowLayoutBottom.self) { proxy in
                    proxy.frame(in: .named("InterestsSection")).maxY
                }
        }
        .padding(.horizontal, -12)
    }
}

struct InterestsBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct FlowLayoutBottom: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ProfileEvent: View {
    let p: UserProfile
    let event: UserEvent?
    
    var body: some View {
        if let event = event {
            EventFormatter(time: event.time, type: event.type, message: event.message, place: event.place, size: 24)
        } else if let idealMeet = p.idealMeetUp {
            EventFormatter(time: idealMeet.time, type: idealMeet.type, message: idealMeet.message, isInvite: true, place: idealMeet.place, size: 24)
        }
    }
}


