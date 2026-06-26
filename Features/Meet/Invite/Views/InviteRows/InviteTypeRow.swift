//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTypeRow: View {

    @Bindable var ui: TimeAndPlaceUIState

    @Binding var type: Event.EventType
    @Binding var unparsedMessage: String?

    @State private var messageHeight: CGFloat = 0

    //The message we last derived a line count from. Lets us ignore height re-measures caused by
    //the margin animation re-wrapping the same text, so the line count (and margin) can't oscillate.
    @State private var lastCountedMessage = ""


    //Chooses which sections info is open, controlled here as need to update
    @State private var openInfoTypes: Set<Event.EventType> = []

    //Pulsed true→false to flex the left title when the type is switched on the message page
    //(see `rowTitle`). The menu closes with `.morphPlatterOnly` there, so this title is what
    //acknowledges the change.
    @State private var typePulse = false

    //Choose corner radius for different drop down menus
    private let menuCorners = RectangleCornerRadii(top: 20, bottom: 6)
    private let footerCorners = RectangleCornerRadii(top: 6, bottom: 18)

    var message: String  {
        (unparsedMessage ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @State private var pageWidth: CGFloat = 0
    @State private var scrollProgress: Double = 0
    @State private var scrolledPageID: Int?

    //Tight global frames of the actual page content + the (out-of-scroll) chevron, measured
    //only by the live label. The glass bloom/collapse morphs around the active page's frame
    //unioned with the chevron instead of the padded scroller frame — see `morphAnchor`.
    //Mirrors InviteTimeRow's frame reads.
    @State private var typeFrame: CGRect = .zero
    @State private var messageFrame: CGRect = .zero
    @State private var chevronFrame: CGRect = .zero

    private var isScrolling: Bool {
        abs(scrollProgress - scrollProgress.rounded()) > 0.01
    }


    var body: some View {
        HStack {
            rowTitle.opacity(ui.typePopupOpen ? 0.3 : 1)
            Spacer(minLength: 16)
            if message.isEmpty {
                inviteTypeButton
            } else {
                inviteTypeScroller
            }
        }
        .overlay(alignment: .bottom) {
            pageIndicator.opacity(ui.typePopupOpen ? 0 : 1)
        }
        //Clearing the message while parked on the message page would otherwise reopen there.
        .onChange(of: message.isEmpty) { _, isEmpty in
            if isEmpty { scrolledPageID = 0; scrollProgress = 0 }
        }
        .task(id: messageHeight) { updateLineHeight() }       //typing: recount once the new text's height settles
        .onChange(of: message) { _, _ in updateLineHeight() } //clearing/edits: recount (and reset) on text change
        //A type switch made while parked on the message page is acknowledged by the left title
        //(the menu only zooms its platter into the chevron) — flex it. Switches on the type page
        //are shown by the menu's own morph, so they don't pulse.
        .onChange(of: type) { _, _ in
            guard onMessagePage else { return }
            pulseTypeTitle()
        }
    }

    private func pulseTypeTitle() {
        typePulse = true
        Task {
            try? await Task.sleep(for: .seconds(DropdownCustomMenuSpec.flexHold))
            typePulse = false
        }
    }
}
extension InviteTypeRow {

    //Message present: the type label + message become swipeable pages, mirroring
    //InviteTimeRow. The menu wraps the pager as its LABEL, so the open-gesture sits ABOVE the
    //scroll — a horizontal drag scrolls the pages and only a stationary tap opens the menu.
    //`isLiveTypeRow` marks THIS as the on-screen copy: the menu's overlay + dismiss-morph
    //copies render without it, so they fall back to a static icon instead of a second live
    //ScrollView that would re-measure into the shared scroll bindings (the jitter/lost-type bug).
    //The chevron-anchored bloom (`morphsFromTrailingPoint`) is only wanted on the message
    //page, where the trailing-aligned message hugs the chevron. On the type page we want the
    //menu to bloom from the whole label — exactly like the no-message compact button — so the
    //flag tracks `onMessagePage` instead of being hard-true.
    private var inviteTypeScroller: some View {
        typeMenu(morphsFromTrailingPoint: onMessagePage, morphAnchor: morphAnchor) { menuLabel }
            .environment(\.isLiveTypeRow, true)
    }

    private var menuLabel: some View {
        TypeRowMenuLabel(
            type: type,
            message: message,
            isPopupOpen: ui.typePopupOpen,
            isScrolling: isScrolling,
            pageWidth: $pageWidth,
            scrollProgress: $scrollProgress,
            scrolledPageID: $scrolledPageID,
            messageHeight: $messageHeight,
            typeFrame: $typeFrame,
            messageFrame: $messageFrame,
            chevronFrame: $chevronFrame
        )
    }

    //Tight rect the glass lens blooms from / collapses into, mirroring InviteTimeRow's
    //`morphAnchor`: the active page's content (type text or message) unioned with the
    //chevron, so the zoom point is the visible label — not the scroller's 30pt vertical
    //padding. nil until measured (and for the compact button, whose frame is already tight).
    private var morphAnchor: CGRect? {
        let content = onMessagePage ? messageFrame : typeFrame
        guard chevronFrame != .zero else {
            return content == .zero ? nil : content
        }
        return content == .zero ? chevronFrame : content.union(chevronFrame)
    }

    //Mirrors InviteTimeRow's title: "What" on the type page, the selected type's
    //short title once you swipe to the message page. On the message page a type switch is
    //shown HERE (the menu only zooms its platter into the chevron): the new title blur-replaces
    //the old, with a quick lift + scale-up that settles back — the same `.flex` acknowledgement
    //the menu gives a no-change dismiss. Driven by `typePulse`, pulsed on the type change below.
    private var rowTitle: some View {
        ZStack(alignment: .leading) {
            Text(rowTitleText.capitalized)
                .font(.body(13, .regular))
                .foregroundStyle(Color(red: 0.70, green: 0.70, blue: 0.75))
                .id(rowTitleTransitionID)
                .transition(.blurReplace)
        }
        .scaleEffect(typePulse ? DropdownCustomMenuSpec.flexScale : 1, anchor: .leading)
        .offset(y: typePulse ? DropdownCustomMenuSpec.flexOffsetY : 0)
        .animation(typePulse ? DropdownCustomMenuSpec.flexUp : DropdownCustomMenuSpec.flexDown, value: typePulse)
        .animation(.snappy(duration: 0.32, extraBounce: 0), value: rowTitleTransitionID)
        .animation(.snappy, value: scrolledPageID)
    }

    private var onMessagePage: Bool {
        !message.isEmpty && (scrolledPageID ?? 0) >= 1
    }

    //Includes the type on the message page so switching it (e.g. "Drinks" → "Date") changes the
    //id and blur-replaces the title; "What" on the type page is type-independent (the menu's own
    //morph shows the switch there).
    private var rowTitleTransitionID: String { onMessagePage ? "type-\(type.title)" : "what" }

    private var rowTitleText: String { onMessagePage ? type.title : "What" }

    @ViewBuilder
    private var pageIndicator: some View {
        if !message.isEmpty {
            AnimatedPageIndicator(count: 2, progress: scrollProgress, inactiveDotSize: 5, activeWidth: 8)
                .scaleEffect(0.6, anchor: .bottom)
                .padding(.bottom, 6)
                .offset(x: 6)
        }
    }
}



//With Message Views
extension InviteTypeRow {

    //Shared menu chrome for both the compact (no-message) trigger and the swipeable pager.
    //`morphsFromTrailingPoint` blooms from the trailing edge when the label is wide (message
    //present); the compact label blooms from its whole frame.
    private func typeMenu<Label: View>(
        morphsFromTrailingPoint: Bool,
        morphAnchor: CGRect? = nil,
        @ViewBuilder label: @escaping () -> Label
    ) -> some View {
        DropdownCustomMenu(
            cornerRadii: menuCorners,
            footerCornerRadii: footerCorners,
            morphsFromTrailingPoint: morphsFromTrailingPoint,
            morphAnchor: morphAnchor,
            flexOnEmptyDismiss: true, //no type change (tap-away / re-pick same) flexes the label instead of morphing
            placementOffsetY: 24, //12pt lower than the 24pt default
            onOpen: { ui.typePopupOpen = true },
            onClose: { ui.typePopupOpen = false ; openInfoTypes.removeAll() },
            footer: { AnyView(addMessageFooter) },
            content: { selectTypeView }, //detached "Add a Message" card lives in the footer below
            label: label
        )
    }

    //No message: the compact trigger. No `isLiveTypeRow`, so TypeRowMenuLabel renders just
    //the static icon (no ScrollView) — exactly the original behaviour.
    private var inviteTypeButton: some View {
        typeMenu(morphsFromTrailingPoint: false) { menuLabel }
    }

    private var selectTypeView: some View {
        SelectTypeView(
            openTypes: $openInfoTypes,
            selectedType: $type,
            showMessageScreen: $ui.showMessageScreen,
            showTypePopup: ui.binding(for: .type),
            message: message,
            onMessagePage: onMessagePage,
            cardCorners: menuCorners
        )
    }

    private func updateLineHeight() {
        //1. No message (incl. clear): reset the count, and the dedupe key so the next message recounts.
        if message.isEmpty {
            ui.messageLineCount = 0
            lastCountedMessage = ""
            return
        }
        guard message != lastCountedMessage, messageHeight > 0 else { return }

        let lineHeight = UIFont.preferredFont(forTextStyle: .footnote).lineHeight
        ui.messageLineCount = min(3, Int((messageHeight / lineHeight).rounded()))
        lastCountedMessage = message
    }

    private var addMessageFooter: some View {
        AddMessageFooter(message: message, corners: footerCorners) {
            ui.showMessageScreen = true
        }
    }
}


//The menu's label. Only the on-screen copy (`isLiveTypeRow`) carries the ScrollView; the
//menu renders its overlay + dismiss-morph copies WITHOUT that flag, so they degrade to the
//static `icon`. That stops a second live ScrollView from re-measuring into the shared
//pageWidth / scrollProgress / scrolledPageID bindings — which made the row jitter and dropped
//the freshly-picked type. Must be its own struct so @Environment resolves where it renders
//(the overlay window), not where the row sits. Mirrors InviteTimeRow's `isLiveTimeRow` split.
private struct TypeRowMenuLabel: View {

    @Environment(\.isLiveTypeRow) private var isLive

    let type: Event.EventType
    let message: String
    let isPopupOpen: Bool
    let isScrolling: Bool
    @Binding var pageWidth: CGFloat
    @Binding var scrollProgress: Double
    @Binding var scrolledPageID: Int?
    @Binding var messageHeight: CGFloat
    //Tight global frames of each page's content + the chevron, fed back to the row so the
    //glass lens morphs around the visible label (not the scroller's padding). Written only
    //here, in the LIVE copy — the overlay/dismiss copies render the static `icon` without
    //these readers, so they never clobber the bindings (mirrors InviteTimeRow's isLive split).
    @Binding var typeFrame: CGRect
    @Binding var messageFrame: CGRect
    @Binding var chevronFrame: CGRect

    var body: some View {
        if isLive { liveLabel } else { icon }
    }

    //Type + message as swipeable pages, à la InviteTimeRow's pager. The chevron sits OUTSIDE
    //the ScrollView (a sibling in the HStack), so it stays put while the pages scroll —
    //mirroring InviteTimeRow, whose chevron is beside the pager, not inside it. The -12 inner
    //offset pulls the trailing-aligned text in, leaving the gap to the pinned chevron.
    private var liveLabel: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    typeText
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { typeFrame = $0 }
                        .frame(width: pageWidth, alignment: .trailing)
                        .id(0)
                    messageView
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { messageFrame = $0 }
                        .frame(width: pageWidth, alignment: .trailing)
                        .id(1)
                }
                .offset(x: -12) //Align with the rest of the content
                .padding(.vertical, 30)
                .scrollTargetLayout()
            }
            .modifier(PagedScrollStyle(
                scrolledPageID: $scrolledPageID,
                pageWidth: $pageWidth,
                scrollProgress: $scrollProgress,
                isScrolling: isScrolling, pageCount: 2
            ))
            chevron
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { chevronFrame = $0 }
        }
    }

    //The static label (text + chevron), used for the overlay/dismiss copies and the compact
    //button. Composed from the same `typeText` / `chevron` the live pager pins separately.
    private var icon: some View {
        HStack(spacing: 12) {
            typeText
            chevron
        }
        .geometryGroup()
        .contentTransition(.opacity)
    }

    private var typeText: some View {
        Text(type.longTitle)
            .font(.body(17, .medium))
            .contentTransition(.opacity)
    }

    private var chevron: some View {
        DropDownButton(isOpen: isPopupOpen)
    }

    private var messageView: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.gray)
            .lineLimit(3)
            .multilineTextAlignment(.trailing)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { messageHeight = $0 }
            .transition(.opacity.animation(.smooth(duration: 0.2)))
    }
}

extension EnvironmentValues {
    @Entry var isLiveTypeRow: Bool = false
}


private struct AddMessageFooter: View {

    @Environment(\.dropdownCustomMenuDismiss) private var menuDismiss

    let message: String
    let corners: RectangleCornerRadii
    let onSelect: () -> Void

    var body: some View {
        Text(message.isEmpty ? "Add a Message" : "Edit Message")
            .foregroundStyle(Color.black)
            .font(.body(16, .bold))
            .kerning(0.5)
            .frame(height: 40)
            .modifier(SelectTypeCardBackground(corners: corners)) //same stroked card as the type list
            .dropdownCustomMenuFooterPlatter(corners: corners) //own the glass platter so the press scales it, not just the inside
            .contentShape(.rect)
            .shrinkPress {
                onSelect()
                Task {
                    try? await Task.sleep(for: .seconds(0.04))
                    menuDismiss(.instant)
                }
            }
    }
}
