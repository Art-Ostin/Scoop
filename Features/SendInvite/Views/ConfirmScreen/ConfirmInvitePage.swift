//
//  ConfirmInviteScreen.swift
//  Scoop
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI

enum ConfirmMode {
    case Invite, Respond
}


struct ConfirmInvitePage: View {
    
    //Injected Properties -> Highly specific so can use for 'RespondInvite' screen as well
    let name: String
    let type: Event.EventType
    let proposedTimes: ProposedTimes
    let place: EventLocation
    let message: String?
    
    @Binding var showConfirmScreen: Bool?
    @Binding var showMessageScreen: Bool

    //Local Properties
    @State private var scrollProgress: Double = 0
    @State private var messageHeight: CGFloat = 0
    @State private var showInfoSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            nameTitle
            scrollView
            warningLabel
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {typeButton}
        .padding(.top, 20)
        .sheet(isPresented: $showInfoSheet) {
            Text(type.longTitle)
                .presentationDetents([.medium])
        }
    }
}


//Components
extension ConfirmInvitePage {
    
    private var nameTitle: some View {
        Text(name)
            .font(.title(24, .bold))
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, Spacing.margin)
    }
    
    
    
    
    
    
    
    
    
    
    private var warningLabel: some View {
        HStack(spacing: Spacing.md){
            Image("ConfirmIcon")
            
            Text("Not showing may result in a blocked account")
                .font(.body(14, .regular))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fillGray.opacity(0.5), in: .rect(cornerRadius: CornerRadius.sm))
        .padding(.horizontal, Spacing.margin)
    }
    
    private var typeButton: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(type.emoji)
                .font(.body(15))
            
            HStack(spacing: 2) {
                Text(type.title)
                    .font(.body(14, .bold))
                    .foregroundStyle(Color.textPrimary.mix(with: Color.accent, by: 0.2)) //Subtle Tint of accent
                    .kerning(-0.1)
                Image(systemName:"info.circle")
                    .font(.body(9, .regular))
                    .foregroundStyle(Color.textPlaceholder.mix(with: Color.accent, by: 0.1)) //Subtle Tint of accent
                    .offset(y: -3)
                    .offset(x: 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, type == .drink ? 6 : 8)
        .background(Color.accent.opacity(0.05).mix(with: Color.fillGray, by: 0.5), in: Capsule())
        .padding(.horizontal, 24)
        .shrinkPress {showInfoSheet = true}
        .offset(y: -1 - (type == .drink ? 0 : 1)) //aligns it vertically for some reason
        .scaleEffect(0.85, anchor: .trailing)
    }
}

//ScrollView
extension ConfirmInvitePage {
    
    
    
    
    
    private var scrollView: some View {
        HorizontalScrollView(progress: $scrollProgress) {
            timePlaceTypeSection
                .fixedSize(horizontal: false, vertical: true)   // pin single-line rows to natural height
                .padding(.horizontal, Spacing.margin)
                .padding(.vertical, 28)                 // pure hit-area; won't scale the type
                .containerRelativeFrame(.horizontal, alignment: .leading)
                .padding(.top, 1) //Subtle visual alignment (as type icon overlay makes it slightly closer)
            
            messageSection
                .padding(.horizontal, Spacing.margin)
                .containerRelativeFrame(.horizontal, alignment: .leading)
        }
        .overlay(alignment: .bottomTrailing) {
            InvitePageIndicator(count: 2, progress: scrollProgress)
                .padding(.trailing, Spacing.lg)
                .padding(.bottom, 18)
        }
        .scrollClipDisabled()
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: true, isCardInvite: true)
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: false, isCardInvite: true)
    }
}

//Confirm InviteScreen detailSection
extension ConfirmInvitePage {
    
    
    private var timePlaceTypeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            timeRow
            placeRow
        }
        .font(.body(17, .medium))
    }
    
    private var timeRow: some View {
        lineSection(image: "EventClockIcon", text: proposedTimes.formatMultipleInvitedDays())
            .foregroundStyle(Color.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            .padding(.top, -Spacing.xxs)
    }
    
    private var placeRow: some View {
        lineSection(image: "EventMapIcon", text: place.name ?? "View on map")
            .shrinkPress {MapsRouter.openGoogleMaps(item: place.mapItem, withDirections: false)}
    }
    
    private func lineSection(image: String, text: String) ->  some View {
        HStack(spacing: Spacing.md) {
            Image(image)
                .frame(width: 20, alignment: .leading)
            
            Text(text)
                .font(.body(18, .medium))
        }
    }
}

// MessageScreen Logic
extension ConfirmInvitePage {
    
    @ViewBuilder
    private var messageView: some View {
        if let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messageText(message: message)
        } else {
            noMessagePlaceholder
        }
    }
    
    private func messageText(message: String) -> some View {
        Text(message)
            .font(.system(size: 14, weight: .regular, design: .default))
            .italic()
            .foregroundStyle(Color.textSecondary)
            .lineSpacing(6)
            .getHeight($messageHeight)
            .offset(y: messageLineCount == 3 ? -Spacing.xs : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottomTrailing) {editMessageButton}
    }
    
    private var editMessageButton: some View {
        HStack(spacing: 2) {
            Text("Edit")
                .font(.body(12, .medium))
            
            Image("EditButtonBlack")
                .scaleEffect(0.8, anchor: .top)
        }
        .shrinkPress {showMessageScreen = true}
    }
    
    
    private var noMessagePlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Improve your invite with a message")
                .font(.body(13, .medium))
                .foregroundStyle(Color.textSecondary)
            
            Text("Add a message")
                .foregroundStyle(Color.textSecondary)
        }
    }
    
    private var messageLineCount: Int {
        guard messageHeight > 0 else { return 0 }
        let lineHeight = UIFont.systemFont(ofSize: 14).lineHeight
        return Int(((messageHeight + 6) / (lineHeight + 6)).rounded())
    }
}

