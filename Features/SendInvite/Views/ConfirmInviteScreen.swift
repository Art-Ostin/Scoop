//
//  ConfirmInviteScreen.swift
//  Scoop
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI

struct ConfirmInviteScreen: View {
    
    //Injected Properties
    let name: String

    @Binding var event: EventFieldsDraft
    @Binding var showConfirmScreen: Bool

    //Local Properties
    var hasMessage: Bool { event.message?.isEmpty == false }

    var body: some View {
        //The "Confirm & Send" pill is the container's persistent button — this screen is
        //only the summary that crossfades into place above it.
        VStack(alignment: .leading, spacing: 32) {
            nameTitle
            VStack(alignment: .leading, spacing: hasMessage ? 12 : 16) {
                typeAndPlace
                timeSection
            }
            warningLabel
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.margin)
        .overlay(alignment: .topTrailing) {infoButton}
        .padding(.top, 20)
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
    
    private var warningLabel: some View {
        HStack(spacing: Spacing.md){
            Image("ConfirmIcon")
            
            
            Text("No-shows will result in your account being blocked")
                .font(.body(14, .regular))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.accent.opacity(0.04), in: .rect(cornerRadius: CornerRadius.sm))
    }

    private var infoButton: some View {
        Image(systemName: "info.circle")
            .foregroundStyle(Color.textSecondary)
            .font(.body(12, .regular))
            .frame(width: 28, height: 28)
            .background(Color.fillGray, in: Circle())
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
