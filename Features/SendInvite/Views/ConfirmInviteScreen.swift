//
//  ConfirmInviteScreen.swift
//  Scoop Test
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI

struct ConfirmInviteScreen: View {
    
    //Injected Properties
    let name: String

    @Binding var event: EventFieldsDraft
    @Binding var showMessageScreen: Bool
    @Binding var showConfirmScreen: Bool
    
    let onSendInvite: () -> ()

    //Local Properties
    var hasMessage: Bool { event.message?.isEmpty == false }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            nameTitle
            VStack(alignment: .leading, spacing: hasMessage ? 12 : 16) {
                typeAndPlace
                timeSection
            }
            sendButtonAndWarning
        }
        .overlay(alignment: .topTrailing) {backButton}
    }
}

//Components
extension ConfirmInviteScreen {
    
    private var nameTitle: some View {
        Text(name)
            .font(.title(24, .bold))
            .foregroundStyle(Color.textPrimary)
    }
    
    private var typeAndPlace: some View {
        return (
            Text(event.type.longTitle)
            +
            Text(" · ")
            +
            Text(event.place?.name ?? "")
        )
        .font(.body(19, .medium))
        .minimumScaleFactor(0.8)
        .lineLimit(1)
    }
    
    private var inviteMessage: some View {
        Text(event.message ?? "")
            .font(.system(size: 14, weight: .regular))
            .italic()
            .foregroundStyle(Color.textTertiary)
    }
    
    private var sendButtonAndWarning: some View {
        let darkRed = Color(red: 0.55, green: 0, blue: 0.25)
        
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("If they accept & I don't show I'll be blocked")
                .font(.body(12, .regular))
                .foregroundStyle(Color.textPlaceholder)
            
            ScoopButton(style: .tinted(darkRed), shape: Capsule()) {
                
            } label: {
                Text("Confirm & Send")
                    .font(.body(18, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
        }
    }
    
    private var backButton: some View {
        Image(systemName: "chevron.down")
            .font(.body(12, .bold))
            .frame(width: 28, height: 28)
            .background(Color.fillGray, in: Circle())
            .offset(y: -4)
            .expandHitArea()
            .profileShrinkPress {showConfirmScreen = false}
    }
    
    private var timeSection: some View {
        let days = event.time.availableDates()

        let value: String = {
            if days.count == 1, let day = days.first {
                return FormatEvent.dayAndTime(day)
            }
            return days.indices.map { index in
                let day = days[index]
                let isLast = index == days.count - 1

                return FormatEvent.shortDayAndTime(
                    day,
                    withHour: isLast
                ) + daySuffix(at: index, dayCount: days.count)
            }
            .joined()
        }()

        return Text(value)
            .font(.body(19, .medium))
            .foregroundStyle(Color.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
    }

    private func daySuffix(at index: Int, dayCount: Int) -> String {
        guard index < dayCount - 1 else {
            return ""
        }

        return index == dayCount - 2 ? " or " : ", "
    }}
