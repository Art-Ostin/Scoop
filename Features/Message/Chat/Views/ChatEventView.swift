//
//  ChatEventView.swift
//  Scoop
//
//  Created by Art Ostin on 05/03/2026.
//


import SwiftUI

struct ChatEventView: View {
    
    private static let locationURL = URL(string: "scoop://event-location")!
    @State private var isLocationPressed = false
    let event: UserEvent?
    
    var body: some View {
        
        if let event = event {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Meeting with \(event.otherUserName)")
                        .font(.body(18, .bold))
                    
                    Spacer()
                    
                    Text(eventType(event: event))
                        .font(.body(13, .bold))
                        .frame(width: 80, alignment: .trailing)
                        .offset(y: -6)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    eventDetails(event: event)
                    if let message = event.message {
                        Text(message)
                            .font(.body(14, .italic))
                            .foregroundStyle(Color.grayText)
                            .lineLimit(2)
                            .lineSpacing(2)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
            .stroke(16, lineWidth: 1, color: Color.accent.opacity(0.15))
            .padding(.horizontal, 32)
        }
    }
}
extension ChatEventView {
    
    private func eventDetails(event: UserEvent) -> some View {
        Text(eventDetailsText(event: event, isLocationPressed: isLocationPressed))
        .font(.body(16, .medium))
        .lineLimit(2)
        .lineSpacing(6)
        .foregroundStyle(Color.black.opacity(0.8))
        .tint(Color.accent)
        .environment(\.openURL, OpenURLAction { url in
            guard url == Self.locationURL else {
                return .systemAction(url)
            }
            Task { @MainActor in
                withAnimation(.easeOut(duration: 0.01)) {
                    isLocationPressed = true
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
                MapsRouter.openGoogleMaps(item: event.location.mapItem)
                try? await Task.sleep(nanoseconds: 250_000_000)
                isLocationPressed = false
            }
            return .handled
        })
    }

    private func eventDetailsText(event: UserEvent, isLocationPressed: Bool) -> AttributedString {
        var details = AttributedString("\(FormatEvent.dayAndTime(event.acceptedTime ?? Date())) · ")
        var location = AttributedString(event.location.name ?? event.location.address ?? "")
        location.link = Self.locationURL
        location.foregroundColor = isLocationPressed ? Color.grayText.opacity(0.5) : Color.accent
        details += location
        return details
    }
    
    private func eventType(event: UserEvent) -> String {
        let type = event.type
        return "\(type.description.emoji) \(type.description.label)"
    }
}

