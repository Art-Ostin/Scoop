//
//  ChatEventView.swift
//  Scoop
//
//  Created by Art Ostin on 05/03/2026.
//


import SwiftUI

struct ChatEventView: View {
    
    //Injected
    let event: UserEvent?

    //Local view state
    @State private var isLocationPressed = false
    private static let locationURL = URL(string: "scoop://event-location")!
    
    var body: some View {
        
        if let event = event {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("\(event.otherUserName) Meeting")
                        .font(.body(18, .bold))
                    
                    Spacer()
                    
                    Text(eventType(event: event))
                        .font(.body(13, .bold))
                        .frame(width: event.type == .doubleDate ? 100 : 80, alignment: .trailing)
                        .lineLimit(1)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    eventDetails(event: event)
                    if let message = event.message {
                        Text(message)
                            .font(.body(14, .italic))
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(2)
                            .lineSpacing(2)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.md)
            .frame(maxWidth: .infinity)
            .stroke(CornerRadius.md, lineWidth: 1, color: Color.accent.opacity(0.15))
            .padding(.horizontal, Spacing.xl)
        }
    }
}
extension ChatEventView {
    
    private func eventDetails(event: UserEvent) -> some View {
        Text(eventDetailsText(event: event, isLocationPressed: isLocationPressed))
        .font(.body(16, .medium))
        .lineLimit(2)
        .lineSpacing(6)
        .foregroundStyle(Color.textPrimary)
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
        location.foregroundColor = isLocationPressed ? Color.textAccent.opacity(0.5) : Color.textAccent
        details += location
        return details
    }
    
    private func eventType(event: UserEvent) -> String {
        let type = event.type
        return "\(type.emoji) \(type.title)"
    }
}
