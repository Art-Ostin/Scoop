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

    //The card's icons are flat white glyphs, so they can wear the artwork tint; a popup's are drawn art
    var iconRendering: Image.TemplateRenderingMode { isCard ? .template : .original }
    
    var timePopupFill: Color? { isCard ? .white : nil }
    
    //The layout metrics set here
    var topPadding: CGFloat { isCard ? 0 : 20 } //No top padding needed if is card
    var timeAndPlaceTopPadding: CGFloat { isCard ? 24 : 26} //Padding to title if card (matches the row spacing, so card reads as one even stack)
    var rowSpacing: CGFloat { isCard ? 26 : 26}
    var rowsBottomPadding: CGFloat { isCard ? 0 : 18} //Below the place row: popup → warning; the card insets at container level instead
    var bottomPadding: CGFloat { isCard ? 0 : 12} //Below the section: card → card bottom, popup → action button
    var iconRowSpacing: CGFloat { isCard ? Spacing.xs : Spacing.sm } //Card tightens to 8; popups keep the 12 they render today
    var timeAndPlaceSizing: CGFloat { isCard ? 20 : 19 }
    
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
    var color: Color? = nil //Artwork-derived tint for the card's rows; nil keeps the style's own foreground

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
        .foregroundStyle(color ?? style.foreground) //Title and type chip set their own white, so only the rows take the tint
        .overlay(alignment: .bottomTrailing) { openInviteButton }
        .padding(.top, style.topPadding)
        .padding(.bottom, style.bottomPadding)
        .padding(.horizontal, Spacing.lg)
        .overlay(alignment: .topTrailing) { if style != .card { InviteInfoButton(showInfo: showInfo).offset(x: -4, y: 2) } }
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
        LineSection(image: .drinkIconDark, text: event.type == .drink ? "Grab a Drink" : event.type == .socialMeet ? "Social Meetup" : event.type.longTitle, style: style)
            .fixedSize(horizontal: true, vertical: false)
            .font(.body(19, .medium))
    }

    //Only used if it is the Confirm Screen within the Card
    private var cardTitle: some View {
        HStack(alignment: .top) {
            Text(nameText)
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)
            Spacer(minLength: 4)
            TypeButton(type: event.type, timeOpen: timeOpen, showInfo: showInfo)
        }
    }
    
    //If Name is 7 or less characters say 'Arthur's Invite' otherwise just their name i.e. Genevieve
    private var nameText: String {
        if name.count <= 7 {
            "\(name)'s Invite"
        } else {
            "\(name)"
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
            InviteButton(onTap: openInvite) //Sits on the rows' bottom edge; the card's inset lifts both
                .offset(y: 4)
        }
    }
}
