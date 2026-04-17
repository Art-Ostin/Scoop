//
//  CoreInfoPage.swift
//  Scoop
//
//  Created by Art Ostin on 16/04/2026.
//

import SwiftUI


enum TextCoreInfo: CaseIterable {
    case certified, type, message, warning
    
    func image(event: UserEvent) -> String {
        switch self {
        case .certified:
            return "TickVector"
        case .type:
            return  event.type.description.emoji
        case .message:
           return "💬"
        case .warning:
            return "⚠️"
        }
    }
    
    func text(event: UserEvent) -> String {
        switch self {
        case .certified:
//            let name = event.location.name ?? "the venue"
            let day = FormatEvent.dayAndTime(event.acceptedTime ?? Date(), wide: true, withHour: false)
            let hour = FormatEvent.hourTime(event.acceptedTime ?? Date())
            return "You've both confirmed you're meeting on \(day) at \(hour)!"
        case .type:
            return event.type.howItWorks(userEvent: event)
        case .message:
            return "Text to coordinate details and find one another when its time"
        case .warning:
            return "You’ve both confirmed so they’ll be there! If you don’t show you’re blocked! "
        }
    }
}


struct CoreInfoPage: View {
    let event: UserEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(TextCoreInfo.allCases, id: \.self) { textInfo in
                eventSection(image: textInfo.image(event: event), text: textInfo.text(event: event))
            }
        }
        .padding(.top, 26)
        .padding(.bottom, 22)
        .padding(.horizontal, 24)
        .background (
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .stroke(24, lineWidth: 1, color: Color(red: 0.93, green: 0.93, blue: 0.93)) //Color(red: 0.93, green: 0.93, blue: 0.93)
        .overlay(alignment: .topLeading) {
            eventDetailsOverlay
        }
    }
    
    private func textSection(image: String, text: String) -> some View {
        Text("Hello World")
    }
    
    
    private var eventDetailsOverlay: some View {
        Text("How it Works")
            .font(.custom("SFProRounded-Medium", size: 10))
            .foregroundStyle(Color(red: 0.68, green: 0.68, blue: 0.68))
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(stops: [
                            .init(color: Color(red: 0.99, green: 0.98, blue: 0.97), location: 0.0),
                            .init(color: Color(red: 0.99, green: 0.98, blue: 0.97), location: 0.5),
                            .init(color: .white,  location: 0.5),
                            .init(color: .white,  location: 1.0)
                        ], startPoint: .top, endPoint: .bottom)
                    )
            )
            .padding(.horizontal, 24)
            .offset(y: -5)
    }
    
    @ViewBuilder
    private func eventSection(image: String, text: String) -> some View {
        HStack(spacing: 16) {
            if image == "TickVector" {
                Image("TickVector")
            } else {
                Text(image)
                    .font(.body(16))
            }
            Text(text)
                .font(.body(15))
                .lineSpacing(5)
        }
        .foregroundStyle(Color(red: 0.25, green: 0.25, blue: 0.25))
    }
}



