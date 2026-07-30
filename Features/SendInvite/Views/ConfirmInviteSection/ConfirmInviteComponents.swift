//
//  ConfirmInviteComponents.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/07/2026.


import SwiftUI

struct InviteName: View {
    let name: String
    let isPopup: Bool

    var body: some View {
        Text(name)
            .font(.title(isPopup ? 24 : 26, .bold))
            .foregroundStyle(isPopup ? Color.textPrimary : Color.white)
            .frame(maxWidth: .infinity, alignment: .leading)
        
    }
}

struct InviteTypeButton: View {

    let type: Event.EventType
    
    @Binding var showInfoSheet: Bool
    var body: some View {
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

struct WarningLabel: View {
    
    var body: some View {
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
}


struct ConfirmInviteScrollView<TimeRow: View>: View {
    
    let invite: InviteSummary
    
    @Binding var showMessageScreen: Bool
    
    @ViewBuilder var timeRow: TimeRow
    
    @State var scrollProgress: Double = 0
    
    var body: some View {
        HorizontalScrollView(progress: $scrollProgress) {
            TimeAndPlaceRows(place: invite.place) {timeRow}
            .popupTimeAndPlaceLayout()
            
            ConfirmMessageSection(message: invite.message, showMessageScreen: $showMessageScreen)
        }
        .overlay(alignment: .bottomTrailing) {
            InvitePageIndicator(count: 2, progress: scrollProgress)
        }
        .scrollClipDisabled()
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: true, isCardInvite: true)
        .customHorizontalScrollFade(width: Spacing.margin, showFade: true, fromLeading: false, isCardInvite: true)
        .padding(.horizontal, -Spacing.margin)
    }
}

extension View {
    func popupTimeAndPlaceLayout() -> some View {
        self
            .fixedSize(horizontal: false, vertical: true)   //pin single-line rows to natural height
            .padding(.horizontal, Spacing.margin)
            .padding(.vertical, 28)                         //Geometry: pure hit-area; won't scale the type
            .containerRelativeFrame(.horizontal, alignment: .leading)
            .padding(.top, 1)                               //Geometry: optical nudge off the page top
    }
}

