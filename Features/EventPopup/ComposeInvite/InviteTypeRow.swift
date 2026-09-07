//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 04/09/2026.
//

import SwiftUI


private let chevronSpacing: CGFloat = 9
private let rowHeight: CGFloat = 33

//While the type menu is open the row's two ends step in to sit as one line just above the platter (the
//InvitePopup row's tuned geometry, Aug 2026): the caption grows and slides in, the value and chevron slide in to meet it
private let openLift: CGFloat = -4 //Geometry: the lift both ends ride, so they stay on one line
private let openShiftX: CGFloat = -20 //Geometry: value and chevron slide left off the row's trailing edge
private let openCaptionShiftX: CGFloat = 24 //Geometry: the caption's tuned slide-in, from the Aug 2026 row
private let openCaptionSize = EventRowText.size //open, the caption reads as one line with the value
//Geometry: the old row anchored the platter 28pt under the value's TEXT top; this menu anchors to the whole label
//frame, whose top sits half the row's slack higher, so that slack is added back
private let menuPlacementOffsetY: CGFloat = 28 + (rowHeight - EventRowText.size) / 2

//The message page's own format while the menu is open: the type reads as one line, and the message keeps this
//much clear air from the end of it — the row's own Spacer minimum plus the 8 the one-line type asks for
private let openMessageGap: CGFloat = 20 + 8
private let messageSize: CGFloat = 14
private let messageShrinkFloor: CGFloat = 13 //the message stops shrinking here and truncates its tail instead

struct InviteTypeRow: View {
    
    //Injected Data to updated
    @Binding var eventType: Event.EventType
    @Binding var message: String?
    
    //Reading 4 states from UI, so passing in whole binding
    @Bindable var ui: ComposeInviteUIState
    let rowHeightIncrease: CGFloat = 19.5 //As need to fit 3 line text on it so fixes bug.
    let timePopupOpen: Bool
    
    //Store which 'info' icons for the selectTypeDowndown open
    @State private var openInfoTypes: Set<Event.EventType> = []
    
    //ScrollProgress Logic
    @State private var messageWidth: CGFloat = 0
    @State private var typeTextWidth: CGFloat = 0
    @State private var typeCaptionWidth: CGFloat = 0
    @State private var captionRect: CGRect = .zero
    @State private var labelRect: CGRect = .zero
    @State private var scrollProgress: Double = 0
    @State private var scrollPosition = ScrollPosition()
    
    var body: some View {
        HStack {
            caption
                .getRect($captionRect) //resting: the open slide is applied inside `caption`, below this read
            Spacer(minLength: 20)//Fine tuned looks good with this
            dropDownMenu
                .getRect($labelRect) //resting likewise: the menu applies labelOffset inside its own body
        }
        .frame(minHeight: rowHeight)
        .background(alignment: .trailing) { textProbes }
        .blurPop(visible: !timePopupOpen, scale: 1)
    }
    
    private var dropDownMenu: some View {
        DropdownCustomMenu(
            placementOffset: CGSize(width: 0, height: menuPlacementOffsetY),
            horizontalPlacement: .centered, //the screen's centre line, on every width; the old row only landed there on 393pt phones
            isOpen: $ui.typePopupOpen,
            showMessageScreen: $ui.showMessageScreen,
            message: message ?? "",
            onClose: { openInfoTypes.removeAll() },
            pressEffect: isOnMessagePage ? .subtleShrink : .shrink,
            labelOffset: isTypeOpen ? CGSize(width: openShiftX, height: openLift) : .zero,
            visibleLabelWidth: visibleLabelWidth,
            content: { selectTypeView },
            label:   { typeLabel }
        )
    }

    private var isTypeOpen: Bool { ui.typePopupOpen }

    //The label runs the full width of the row (its pager fills it), but only the value and chevron are drawn.
    //The menu morphs THIS instead, so the dismiss circle is born on the value rather than mid-row.
    private var visibleLabelWidth: CGFloat? {
        guard typeTextWidth > 0 else { return nil }
        return typeTextWidth + chevronSpacing + DropDownButton.width + 1 //Geometry: +1 of slack, so a rounding difference can't truncate the value
    }

    //Measures the value and the caption exactly as they are drawn, but OUTSIDE the label closure — the menu
    //builds copies of that closure, and a probe inside it would have every copy write this row's state
    private var textProbes: some View {
        ZStack {
            EventRowText(text: eventType.longTitle)
                .fixedSize()
                .getWidth($typeTextWidth)
            Text(eventType.longTitle) //the caption's one-line width, known before the menu opens
                .font(.body(RowCaption.size, .medium))
                .fixedSize()
                .getWidth($typeCaptionWidth)
        }
        .hidden()
    }

    //Open, the caption slides right onto one line while the label slides left, and the two would meet over the
    //message. The message page gives the gap back from its own leading edge, so the pager itself never resizes
    //(its width feeds the scroll progress that decides which page the caption is showing).
    private var messageLeadingInset: CGFloat {
        guard isTypeOpen, isOnMessagePage, typeCaptionWidth > 0, labelRect.width > 0 else { return 0 }
        let captionTextEnd = captionRect.minX + openCaptionShiftX + typeCaptionWidth
        let messageStart = labelRect.minX + openShiftX
        return max(0, captionTextEnd + openMessageGap - messageStart)
    }
    
    //The type view I open up
    private var selectTypeView: some View {
        SelectTypeView(
            openTypes: $openInfoTypes,
            selectedType: $eventType,
            showMessageScreen: $ui.showMessageScreen,
            message: message ?? ""
        )
    }
    
    private var infoIcon: some View {
        Button {
            ui.showInfoScreen = true
        } label: {
            SmallInfoIcon()
                .scaleEffect(0.8)
                .expandHitArea()
                .offset(x: 16, y: -2)
        }
    }
    
    private var typeLabel: some View {
        HStack(spacing: chevronSpacing) {
            typePager
                .padding(.top,    -(rowHeightIncrease/2 + contentLift))
                .padding(.bottom, -(rowHeightIncrease/2 - contentLift))
            DropDownButton(isOpen: isTypeOpen)
        }
    }
    
    private var typePager: some View {
        HorizontalScrollView(
            progress: $scrollProgress,
            alignment: .center,
            position: $scrollPosition) {
                typeTitle.id(0)
                
                if let visibleMessage { eventMessage(text: visibleMessage).id(1) }
            }
            .mask { edgeFadeMask }                          // ← new: fades the pages only
            .animation(.easeOut(duration: 0.06), value: isScrolling)
            .overlay(alignment: .bottomTrailing) {if visibleMessage != nil {pageIndicator } }
            .scrollDisabled(visibleMessage == nil)
            .onChange(of: message) { scrollPosition.scrollTo(id: 1) }
            .onChange(of: eventType) { withAnimation(.easeInOut(duration: 0.3)) {scrollPosition.scrollTo(id: 0)} }
    }
    
    private var isOnMessagePage: Bool { scrollProgress > 0.5 }
    
    private var caption: some View {
        captionContent
            //The grown caption reaches past the resting box the icon is anchored to, so the icon steps aside
            .overlay(alignment: .topTrailing) { infoIcon.opacityPop(visible: !isTypeOpen) }
            .frame(width: 48, alignment: .leading)
            .offset(x: isTypeOpen ? openCaptionShiftX : 0, y: isTypeOpen ? openLift : 0)
            .animation(.toggle, value: isTypeOpen)
            .animation(.transition, value: isOnMessagePage)
    }
    
    private var captionContent: some View {
        ZStack {
            if isOnMessagePage {
                //Stays at rest size: "Custom Meet" already fills the 48pt column at 13pt, so only the colour
                //lights up. Open, it reads as ONE line — two wrapped lines run into the message once the row's
                //two ends step toward each other — taking its natural width out past the column, which the
                //message page then gives back from its leading edge
                Text(eventType.longTitle)
                    .font(.body(RowCaption.size, .medium))
                    .foregroundStyle(isTypeOpen ? Color.textPrimary : Color.textTertiary)
                    .lineLimit(isTypeOpen ? 1 : 2)
                    .fixedSize(horizontal: isTypeOpen, vertical: true)
                    .transition(.blurReplace)
            } else {
                whatCaption
                    .transition(.blurReplace)
            }
        }
    }

    //Two crisp Texts crossfading under one scale: a Text resting at a scale is a soft bitmap, so each size draws itself.
    //The grown twin is an overlay, so the caption's layout box stays the resting caption's
    private var whatCaption: some View {
        let grown = openCaptionSize / RowCaption.size
        return RowCaption(label: .what)
            .scaleEffect(isTypeOpen ? grown : 1, anchor: .leading)
            .opacity(isTypeOpen ? 0 : 1)
            .overlay(alignment: .leading) {
                Text(RowCaption.Label.what.text)
                    .font(.body(openCaptionSize, .medium))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize()
                    .scaleEffect(isTypeOpen ? 1 : 1 / grown, anchor: .leading)
                    .opacity(isTypeOpen ? 1 : 0)
            }
    }
    
    //Steps aside while this row's own menu is up (delayed, to sync with the platter bloom)
    private var pageIndicator: some View {
        InvitePageIndicator(count: 2, progress: scrollProgress)
            .animation(.move, value: indicatorOffset)
            .offset(y: indicatorOffset)
            .opacityPop(visible: !ui.delayedTypePopupOpen)
            .animation(.transition, value: ui.delayedTypePopupOpen)
    }
    
    private var typeTitle: some View {
        EventRowText(text: eventType.longTitle)
            .containerRelativeFrame(.horizontal, alignment: .trailing)
            .frame(height: rowHeight + rowHeightIncrease)
            .offset(y: contentLift) //Cancels the box lift: only the message page should rise
    }
    
    
    //Key fixes bug
    private var visibleMessage: String? {
        guard let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return message
    }
    
    private func eventMessage(text: String) -> some View {
        Text(text)
            .font(.body(messageSize, .regularItalic))
            .foregroundStyle(Color.textSecondary.opacity(0.7)) //Tad lighter than normal secondary
            .lineLimitAndShrink(3, minimum: messageShrinkFloor / messageSize) //then the tail truncates
            .frame(maxWidth: .infinity, alignment: .trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background { Color.clear.getWidth($messageWidth) }
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.trailing)
            .padding(.leading, messageLeadingInset) //Inside the page's own width, so the pager keeps its size
            .containerRelativeFrame(.horizontal)
            .frame(height: rowHeight + rowHeightIncrease)
            .offset(y: messageLineCount == 2 ? -5 : 0) //3 lines lift via contentLift instead: no slack to translate into
    }
    
    private var messageLineCount: Int {
        let metrics = visibleMessage?.lineMetrics(
            font: .body(messageSize, .regularItalic), //lineMetrics' contract: must match the drawn Text exactly
            lineSpacing: 0,                           //The drawn Text sets none
            width: messageWidth
        )
        return min(3, metrics?.count ?? 0) //It measures at full size; the drawn text shrinks and never passes 3
    }
    
    //Three lines fill the page to within 1.05pt, so the lift has to move the BOX, not the content
    private var contentLift: CGFloat { messageLineCount == 3 ? 5 : 0 }

    private var indicatorOffset: CGFloat {
        guard scrollProgress > 0.5 else { return -6 }   //Title page: no nudge
        return switch messageLineCount {
            case 1:  -6
            case 2:  -4
            default:  5 //+2 on the lift, so the gap to a 3-line message widens rather than rides up
        }
    }
    
    
    private var isScrolling: Bool { scrollProgress > 0.01 && scrollProgress < 0.99 }

    private var edgeFadeMask: some View {
        let w: CGFloat = isScrolling ? Spacing.md : 0
        return HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing).frame(width: w)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: w)
        }
    }
}
