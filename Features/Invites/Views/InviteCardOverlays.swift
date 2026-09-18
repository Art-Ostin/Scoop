//
//  InviteCardOverlays.swift
//  Scoop
//
//  Created by Art Ostin on 04/09/2026.
//

import SwiftUI

//The glass inset plus its padding is the one column the title, the icons and the button's trailing edge share (34pt).
//The respond card lands them on 24: every flight poses its pieces as insets and closes that gap on the way
private let glassInset = Spacing.md //Card edge ↔ glass, on the sides and the foot
private let glassPadding = Spacing.md + 2 //Glass edge ↔ its rows
private let glassRadius = max(CornerRadius.concentric(in: ZoomStyle.cornerRadius, inset: glassInset), CornerRadius.sm)
private let rowSize = EventZoomRowMorph.sourceSize //The row flight's source type, so the card and its flying copy can't disagree
private let footTrim = 0.13 * rowSize //Geometry: ModernEra's cap top sits 0.085em under its line box, its baseline 0.215em over the foot — trimming the difference evens the glass above the first capital and below the last baseline
private let paneBlurRadius: CGFloat = 24 //What the card's glur reached at its foot, now flat across the pane and nowhere else
private let buttonReserve: CGFloat = 42 + Spacing.xs //Geometry: InviteButton's circle, plus the gap the words keep from it

//Main Overlay of the card
struct InviteCardOverlay: View {

    let draft: RespondDraft
    let name: String
    let image: UIImage //The artwork the pane frosts a window into
    let surface: Color //The tone the artwork gave us, near-black already; the pane mixes and weights it
    var titleRect: Binding<CGRect> = .constant(.zero) //Where the name's frost is cut, in the card's space
    let openInvite: () -> ()

    ///The card's own space. The name reports its glyphs into it, and the card cuts the frost there.
    static let cardSpace = "inviteCardBand"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            title

            VStack(alignment: .leading, spacing: 22) {
                typeRow

                //Both fly into the respond card's own rows, restyling on the way (`.eventZoomRowTarget`)
                lineSection(.whiteClock, timeText)
                    .eventZoomTimeSource(timeText)
                    .lineLimitAndShrink(1)
                    .padding(.trailing, buttonReserve) //Only the time row runs beside the centred button. Outside the marker, so the flight measures the row itself

                lineSection(.whiteMap, placeText)
                    .lineLimit(1)
                    .eventZoomPlaceSource(placeText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, glassPadding)
            .padding(.top, glassPadding)
            .padding(.bottom, glassPadding - footTrim)
            .overlay(alignment: .trailing) { inviteButton }
            .containerGlassEffect(clear: true, tint: .clear, clipped: true, shape: .rect(cornerRadius: glassRadius))
            .background { paneBackdrop } //Behind the lens, so the clear glass has a blurred, veiled backdrop to refract instead of sharp artwork
            .padding([.horizontal, .bottom], glassInset)
        }
    }
}

extension InviteCardOverlay {

    //A window cut into the artwork: inside the pane the photo is blurred and veiled, outside it stays
    //sharp. Blur-then-mask, never mask-then-blur — masking first lets the gaussian smear past the
    //pane's edge and go translucent at its rim. The copy is drawn at card size and pushed back into
    //place off the pane's own geometry (the pane sits `glassInset` in from three card edges), so the
    //card's veil lands exactly where it always did and nothing has to be measured
    private var paneBackdrop: some View {
        GeometryReader { proxy in
            let pane = proxy.size
            let cardWidth = pane.width + glassInset * 2
            let cardHeight = cardWidth / AspectRatio.inviteCard.ratio
            Color.clear
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .padding(-paneBlurRadius) //Load-bearing: .blur samples transparency past the layer, so without the overhang the rim fades out over a band one radius wide
                }
                .frame(width: cardWidth, height: cardHeight)
                .blur(radius: paneBlurRadius)
                .overlay { paneVeil }
                .offset(x: -glassInset, y: -(cardHeight - glassInset - pane.height))
        }
        .clipShape(.rect(cornerRadius: glassRadius))
        .allowsHitTesting(false)
    }

    //The card's own scrim, drawn at card size so the pane shows the exact slice of the ramp it used
    //to wear — the tone is the artwork's, pulled halfway to black
    private var paneVeil: some View {
        BlurAndGradientBackground(
            textRegion: BlurAndGradientBackground.inviteRegion,
            colour: panelTone,
            scrimOpacity: BlurAndGradientBackground.inviteScrimOpacity
        ).scrimGradient
    }

    private var panelTone: Color {
        surface.mix(with: .black, by: BlurAndGradientBackground.inviteScrimBlackMix) //Perceptual: hue holds while lightness and chroma come down together
    }

    //Only the name is marked: it flies alone into the respond card's "<name>'s Invite", where the suffix waits for it
    private var title: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(name)
                .eventZoomTitleSource(name)
            Text("'s Invite")
        }
        .font(.title(20, .bold))
        .foregroundStyle(Color.white)
        .lineLimit(1) //A wrapping title would hand the flight a two-line frame
        .getRect(titleRect, coordSpace: Self.cardSpace) //Inside the padding: the glyphs, not the slot — the frost is cut to the word
        .padding(.horizontal, glassInset + glassPadding) //Starts over the icons
    }

    private var typeRow: some View {
        HStack(spacing: EventZoomRowMorph.sourceIconGap) {
            Text(eventType.emoji)
                .font(.body(14)) //Fills the icon column, its ink the clock's and pin's size
                .frame(width: EventZoomRowMorph.iconWidth)

            Text(eventType.longTitle)
                .font(.body(rowSize, .medium))
                .foregroundStyle(Color.white)
                .lineLimit(1)
        }
    }

    //The row flight's geometry: its source copy draws this same column, gap, type and nudge
    private func lineSection(_ image: ImageResource, _ text: String) -> some View {
        HStack(spacing: EventZoomRowMorph.sourceIconGap) {
            Image(image)
                .scaleEffect(EventZoomRowMorph.sourceIconScale)
                .frame(width: EventZoomRowMorph.iconWidth)
                .offset(y: -2) //Geometry: centres the glyph on the capitals — the nudge the flight releases as it lands

            Text(text)
                .font(.body(rowSize, .medium))
                .foregroundStyle(Color.white)
        }
    }

    //Centred on the glass's height: level with the time row, clear of the other two. A 42pt circle can't sit concentric in the glass's 12pt corner, so the corner is never its home
    private var inviteButton: some View {
        InviteButton(onTap: openInvite)
            .eventZoomButtonSource() //Widens into the respond card's CTA — inside the padding, so it measures the circle itself
            .padding(.trailing, glassPadding)
    }
}

//What gets shown on the card depends on what sort of invite it is
extension InviteCardOverlay {
    
    private var placeText: String {
        switch draft.respondType {
        case .newEvent: draft.newEvent.place?.name ?? "Unknown"
        default: draft.originalInvite.event.location.name ?? "Unknown"
        }
    }
    
    
    private var timeText: String {
        switch draft.respondType {
        //Scenario 1: In Original Invite
        case .originalInvite:
            //First try and get the first selected date
            if let date = draft.originalInvite.selectedDay {
                return FormatEvent.shortDayAndTime(date)
                
                //That failing, get the first available Date
            } else if let date = draft.originalInvite.event.proposedTimes.firstAvailableDate {
                return FormatEvent.shortDayAndTime(date)
                //It should not be of type original Invite if no availble dates (should have updated) so
            } else {
                return " "
            }
            
        case .newTime:
            let proposedTimes = draft.newTime.proposedTimes
            //If there are any available times list those
            if !proposedTimes.dates.isEmpty {
                if let time = proposedTimes.dates.first {
                    return FormatEvent.shortDayAndTime(time.date)
                } else {
                    return ""
                }
            }
            //If no available Times use last originalInvite Time
            else {
                if let lastDay =  draft.originalInvite.event.proposedTimes.dates.last {
                    return FormatEvent.shortDayAndTime(lastDay.date)
                } else {
                    //That should always exist, if not just for whatever reason have this
                    return "Time Expired"
                }
            }
            
        case .newEvent:
            let proposedTimes = draft.newEvent.time.dates
            //If there are proposedTimes do this
            
            if !proposedTimes.isEmpty {
                if let time = proposedTimes.first {
                   return FormatEvent.shortDayAndTime(time.date)
                } else {
                    return ""
                }
            } else {
                //If there are no proposedTimes get them if there are any in the proposedInvites
                return "Time not Chosen"
            }
        }
    }
    
    private var eventType: Event.EventType {
        if case .newEvent = draft.respondType { return draft.newEvent.type }
        return draft.originalInvite.event.type
    }
}




//The 'Response' capsule: the invite's history, from the card's top-trailing corner
struct InviteHistoryButton: View {

    //Injected
    let action: () -> Void
    @Environment(\.eventZoomCornerSource) private var role //Live on the card; inert, or a bare slot, in the event zoom's flying chrome copy

    var body: some View {
        switch role {
        case .live:
            ScoopButton(style: Self.style, shape: .capsule, action: action) { Self.label }
                .buttonStyle(.automatic) //Its own press, not the card's: it sits inside the card's zoom Button, whose style would reach it
        case .inert:
            Self.capsule
        case .ghost:
            Self.label.hidden()
        }
    }

    //One style for both forms, so the capsule the corner hero flies can never drift from the button it takes off from
    private static let style: ScoopButtonStyle = .clearGlass

    ///ScoopButton's glass path without the Button: the flying copy, and what the corner hero takes off as
    static var capsule: some View {
        label
            .scoopGlassSurface(clear: Self.style == .clearGlass, shape: Capsule())
            .glassFallbackRestingShadow() //See EventBackButton.surface
    }

    private static let fontSize: CGFloat = 12
    static let height = fontSize + 2 * Spacing.xxs //Geometry: ModernEra's line box is its point size — what the card seats concentrically in its corner

    private static var label: some View {
        Text("Response")
            .font(.body(fontSize, .bold))
            .padding(.vertical, Spacing.xxs)
            .padding(.horizontal, Spacing.xs)
            .foregroundStyle(Color.textPrimary)
    }
}
