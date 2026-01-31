//
//  DetailsInfo.swift
//  Scoop
//
//  Created by Art Ostin on 02/11/2025.


import SwiftUI
import SwiftUIFlowLayout


struct UserKeyInfo: View {
    let p : UserProfile
    var hometownCount: Int { p.hometown.count}
    
    var body : some View {
        if hometownCount <= 14 {
            keyInfoOneLine
        } else {
            keyInfoScrollView
        }
        Divider().background(Color.grayPlaceholder)
        InfoItem(image: "ScholarStyle", info: p.degree)
        Divider().background(Color.grayPlaceholder)
        InfoItem(image: "magnifyingglass", info: p.lookingFor)
            .onAppear {
                print(hometownCount)
            }
    }
}

extension UserKeyInfo {

    private var keyInfoOneLine: some View {
        HStack(alignment: .center) {
                InfoItem(image: "Year", info: p.year)
                Spacer()
                InfoItem(image: "Height", info: ("193cm"))
                Spacer()
                InfoItem(image: "House", info: p.hometown)
            }
    }

    private var keyInfoScrollView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 24) {
                InfoItem(image: "Year", info: p.year)
                InfoItem(image: "Height", info: ("193cm"))
                InfoItem(image: "House", info: p.hometown)
            }
        }
        .padding(.vertical, 12) //Trick to expand the tap area of the view so scrolls easier
        .contentShape(Rectangle())
        .padding(.vertical, -12)
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
        if let event = event, let time = event.acceptedTime {
            EventFormatter(time: time, type: event.type, message: event.message, place: event.place, size: 24)
        } else if let idealMeet = p.idealMeetUp {
            EventFormatter(time: idealMeet.time, type: idealMeet.type, message: idealMeet.message, isInvite: true, place: idealMeet.place, size: 24)
        }
    }
}
