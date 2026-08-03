//
//  ConfirmContainer.swift
//  Scoop
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI


enum ConfirmStyle {
    
    case card, popup, respondPopup

    
    var isCard: Bool { self == .card }

    //The card vs Popup Colouring
    var foreground: Color { isCard ? .white : .textPrimary }
    var clockIcon: ImageResource { isCard ? .whiteClock : .eventClockIcon }
    var mapIcon: ImageResource { isCard ? .whiteMap : .eventMapIcon }
    
    var timePopupFill: Color? { isCard ? .white : nil }
    
    //The layout metrics set here
    var topPadding: CGFloat { isCard ? 0 : 26} //No top padding needed if is card
    var timeAndPlaceTopPadding: CGFloat { isCard ? Spacing.lg : 26} //Padding to title if card (matches the row spacing, so card reads as one even stack)
    var rowSpacing: CGFloat { isCard ? 22 : 26}
    var rowsBottomPadding: CGFloat { isCard ? 28 : 26} //Below the place row: card → card bottom, popup → warning
    var bottomPadding: CGFloat { isCard ? 0 : 12} //Below the section: card → rowsBottomPadding already reaches the card bottom, popup → action button
    
    //Only a popup shows these
    var showsWarning: Bool { !isCard }
    var showScrollView: Bool { !isCard }
}

struct ConfirmContainer<TimeRow: View>: View {

    //Injected
    let event: InviteSummary
    let name: String
    let style: ConfirmStyle
    let timeOpen: Bool
    let showMessageSection: Bool
        
    @Binding var showMessageScreen: Bool
    @ViewBuilder var timeRow: TimeRow

    let showInfo: () -> ()
    var openInvite: (() -> Void)? = nil

    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .blurPop(visible: !timeOpen, scale: 1)
            timeAndPlaceRows
            warning
                .blurPop(visible: !timeOpen, scale: 1)
        }
        .foregroundStyle(style.foreground)
        .overlay(alignment: .bottomTrailing) { openInviteButton }
        .padding(.top, style.topPadding)
        .padding(.bottom, style.bottomPadding)
        .padding(.horizontal, Spacing.lg)
        .overlay(alignment: .topTrailing) { if style != .card { InviteInfoButton(showInfo: showInfo) } }
    }
}


//All the 'components' placed here
extension ConfirmContainer {

    //The card wears the name and a type chip; a sheet wears the type row
    @ViewBuilder
    private var header: some View {
        if style == .card {
            cardTitle
        } else {
            typeRow
        }
    }

    private var typeRow: some View {
        LineSection(image: .drinkIconDark, text: event.type.longTitle)
            .fixedSize(horizontal: true, vertical: false)
            .font(.body(18, .medium))
    }

    //Only used if it is the Confirm Screen within the Card
    private var cardTitle: some View {
        HStack {
            Text(name)
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)
            Spacer(minLength: 4)
            TypeButton(type: event.type, timeOpen: timeOpen, showInfo: showInfo)
        }
    }

    private var timeAndPlaceRows: some View {
        ConfirmTimeAndPlace(
            place: event.place,
            message: event.message,
            showMessageSection: showMessageSection,
            timeOpen: timeOpen,
            style: style,
            showMessageScreen: $showMessageScreen,
            timeRow: { timeRow }
        )
    }

    //Sheet only — the card has no room for it
    @ViewBuilder
    private var warning: some View {
        if style.showsWarning {
            WarningLabel()
        }
    }

    @ViewBuilder
    private var openInviteButton: some View {
        if let openInvite {
            InviteButton(onTap: openInvite)
                .padding(.bottom, Spacing.lg)
        }
    }
}
