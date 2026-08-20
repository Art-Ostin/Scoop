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

//The card's title copy — one source of truth shared by the card, the respond popup's
//carousel title and the quick-invite flight's hero text, so the three renderings can't drift.
enum InviteCardTitle {
    ///Name of 7 or fewer characters reads "Arthur's Invite"; a longer one is just the name
    static func text(name: String) -> String {
        name.count <= 7 ? "\(name)'s Invite" : name
    }
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

    //The quick-invite flight's destination anchors: global rects of the rows its hero text
    //lands on, reported only when a flight asks (nil everywhere else)
    var typeRowFrame: Binding<CGRect>? = nil
    var placeRowFrame: Binding<CGRect>? = nil

    //The flight's SOURCE anchors, measured on the real resting card (.card style): where the
    //title, chip and envelope actually lay out. Render-offset asymmetry: the chip's 4.5 lives
    //INSIDE TypeButton, so its measurement excludes it (the flight re-adds it); the
    //envelope's 4 is applied OUTSIDE its measuring modifier below, so its measurement already
    //carries it (the flight must NOT re-add it).
    var cardTitleFrame: Binding<CGRect>? = nil
    var chipFrame: Binding<CGRect>? = nil
    var envelopeFrame: Binding<CGRect>? = nil

    @ViewBuilder var timeRow: TimeRow

    let showInfo: () -> ()
    var openInvite: (() -> Void)? = nil

    //The quick-invite flight's exit drivers; at rest every one is identity
    @Environment(\.inviteRowsFlying) private var rowsFlying
    @Environment(\.inviteBottomChromeIn) private var bottomChromeIn
    @Environment(\.inviteChromeFade) private var chromeFade
    @Environment(\.inviteChromeExiting) private var chromeExiting
    @Environment(\.inviteChromeCollapse) private var chromeCollapse

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .blurPop(visible: !timeOpen, scale: 1)
                //While the flight's hero text owns the title/type it never renders here; a
                //flight with no heroes (a non-accept mount) rushes it out with the scrim instead
                .opacity(rowsFlying ? 0 : chromeFade)
            timeAndPlaceRows
            warning
                .blurPop(visible: !timeOpen, scale: 1)
                //Hidden from the flight's first frame (a visible-at-mount gate faded it OUT
                //over the launch — device video 2026-08-20), popped in on the open spring's
                //clock so it arrives with the settle, and back out at close start
                .blurPop(visible: bottomChromeIn)
                .animation(.transition, value: bottomChromeIn)
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
        //The type reads the card chip's own copy ("Grab Drinks") — the quick-invite flight
        //morphs the chip's text into this row, so the two must be the same words
        LineSection(image: .drinkIconDark, text: event.type.longTitle, style: style)
            .fixedSize(horizontal: true, vertical: false)
            .font(.body(19, .medium))
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { typeRowFrame?.wrappedValue = $0 }
    }

    //Only used if it is the Confirm Screen within the Card
    private var cardTitle: some View {
        HStack(alignment: .top) {
            Text(InviteCardTitle.text(name: name))
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cardTitleFrame?.wrappedValue = $0 }
            Spacer(minLength: 4)
            TypeButton(type: event.type, timeOpen: timeOpen, showInfo: showInfo)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { chipFrame?.wrappedValue = $0 }
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
            placeRowFrame: placeRowFrame,
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
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { envelopeFrame?.wrappedValue = $0 }
                .offset(y: 4)
                //The quick-invite flight: while the CTA hero owns the envelope (it widens into
                //the Accept button) this copy never renders; a hero-less flight falls back to
                //the meet card's invite-icon exits — pop away at launch, revealed by the collapse
                .opacityPop(visible: !chromeExiting)
                .animation(.transition, value: chromeExiting)
                .opacity(rowsFlying ? 0 : chromeCollapse)
        }
    }
}
