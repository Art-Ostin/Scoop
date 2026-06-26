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
    //Last message we counted lines from: ignores height re-measures from the margin
    //animation re-wrapping the same text, so the line count can't oscillate.
    @State private var lastCountedMessage = ""
    @State private var openInfoTypes: Set<Event.EventType> = []
    @State private var typePulse = false

    @State private var scrollProgress: Double = 0
    @State private var scrolledPageID: Int?

    @State private var typeFrame: CGRect = .zero
    @State private var messageFrame: CGRect = .zero
    @State private var chevronFrame: CGRect = .zero

    private let menuCorners = RectangleCornerRadii(top: 20, bottom: 6)
    private let footerCorners = RectangleCornerRadii(top: 6, bottom: 18)

    var message: String {
        (unparsedMessage ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var onMessagePage: Bool {
        !message.isEmpty && (scrolledPageID ?? 0) >= 1
    }

    var body: some View {
        HStack(spacing: 4) {
            rowTitle.opacity(ui.typePopupOpen ? 0.3 : 1)
            Spacer(minLength: 0)
            if message.isEmpty { inviteTypeButton } else { inviteTypeScroller }
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
        .onChange(of: type) { _, _ in if onMessagePage { pulseTypeTitle() } }
    }
}

extension InviteTypeRow {

    // MARK: Row title

    private var rowTitle: some View {
        Text(rowTitleText.capitalized)
            .font(.body(13, .regular))
            .foregroundStyle(Color(red: 0.70, green: 0.70, blue: 0.75))
            .id(rowTitleTransitionID)
            .transition(.blurReplace)
            .multilineTextAlignment(.leading) //so "Double Date" stays on one line
            .frame(width: 47, alignment: .leading)
            .lineSpacing(2)
            .scaleEffect(typePulse ? DropdownCustomMenuSpec.flexScale : 1, anchor: .leading)
            .offset(y: typePulse ? DropdownCustomMenuSpec.flexOffsetY : 0)
            .animation(typePulse ? DropdownCustomMenuSpec.flexUp : DropdownCustomMenuSpec.flexDown, value: typePulse)
            .animation(.snappy(duration: 0.32, extraBounce: 0), value: rowTitleTransitionID)
            .animation(.snappy, value: scrolledPageID)
    }

    private var rowTitleText: String { onMessagePage ? type.title : "What" }

    //On the message page the id carries the type, so switching it (e.g. "Drinks" → "Date")
    //blur-replaces the title; "What" on the type page is type-independent (the menu morph shows that switch).
    private var rowTitleTransitionID: String { onMessagePage ? "type-\(type.title)" : "what" }

    @ViewBuilder
    private var pageIndicator: some View {
        if !message.isEmpty {
            AnimatedPageIndicator(count: 2, progress: scrollProgress, inactiveDotSize: 5, activeWidth: 8)
                .scaleEffect(0.6, anchor: .bottom)
                .padding(.bottom, 6)
                .offset(x: 6)
        }
    }

    private func pulseTypeTitle() {
        typePulse = true
        Task {
            try? await Task.sleep(for: .seconds(DropdownCustomMenuSpec.flexHold))
            typePulse = false
        }
    }

    // MARK: Menu

    //Shared chrome for both the compact (no-message) trigger and the swipeable pager.
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
            flexOnEmptyDismiss: true, //no type change flexes the label instead of morphing
            placementOffsetY: 24,
            onOpen: { ui.typePopupOpen = true },
            onClose: { ui.typePopupOpen = false; openInfoTypes.removeAll() },
            onLabelTap: handleScrollerTap,
            footer: { AnyView(addMessageFooter) },
            content: { selectTypeView },
            label: label
        )
    }

    private var inviteTypeScroller: some View {
        typeMenu(morphsFromTrailingPoint: onMessagePage, morphAnchor: morphAnchor) { menuLabel }
            .environment(\.isLiveTypeRow, true)
    }

    //No message: the compact trigger. Without `isLiveTypeRow`, TypeRowMenuLabel renders just the static icon.
    private var inviteTypeButton: some View {
        typeMenu(morphsFromTrailingPoint: false) { menuLabel }
    }

    private var menuLabel: some View {
        TypeRowMenuLabel(
            type: type,
            message: message,
            isPopupOpen: ui.typePopupOpen,
            scrollProgress: $scrollProgress,
            scrolledPageID: $scrolledPageID,
            messageHeight: $messageHeight,
            typeFrame: $typeFrame,
            messageFrame: $messageFrame,
            chevronFrame: $chevronFrame
        )
    }

    //Union of the active content page and the chevron, ignoring frames not yet measured.
    private var morphAnchor: CGRect? {
        let content = onMessagePage ? messageFrame : typeFrame
        let union = [content, chevronFrame].filter { $0 != .zero }.reduce(CGRect.null) { $0.union($1) }
        return union.isNull ? nil : union
    }

    //A tap while parked on the message page opens the message editor instead of the menu; the type
    //page (and the compact button) fall through. Returning true claims the tap so the menu stays shut.
    private func handleScrollerTap() -> Bool {
        guard onMessagePage else { return false }
        ui.showMessageScreen = true
        return true
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

    private var addMessageFooter: some View {
        AddMessageFooter(message: message, corners: footerCorners) {
            ui.showMessageScreen = true
        }
    }

    private func updateLineHeight() {
        //No message (incl. clear): reset the count and the dedupe key so the next message recounts.
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
}


private struct TypeRowMenuLabel: View {

    @Environment(\.isLiveTypeRow) private var isLive

    let type: Event.EventType
    let message: String
    let isPopupOpen: Bool
    @Binding var scrollProgress: Double
    @Binding var scrolledPageID: Int?
    @Binding var messageHeight: CGFloat

    @Binding var typeFrame: CGRect
    @Binding var messageFrame: CGRect
    @Binding var chevronFrame: CGRect

    //Local to the live pager — the parent never reads it, only this label measures and lays out from it.
    @State private var pageWidth: CGFloat = 0

    var body: some View {
        if isLive { liveLabel } else { icon }
    }

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
                        //Hold the message 12pt clear of the type page's leading edge, cancelling the -12 strip
                        //the parent offset bleeds into the next page (the "a" peeking onto the type page) so the
                        //two pages keep a 12pt gap while the message still reaches its own viewport edge.
                        .padding(.leading, 12)
                        .frame(width: pageWidth, alignment: .trailing)
                        .id(1)
                }
                .offset(x: -12) //align with the rest of the content
                .frame(height: 75)
                .scrollTargetLayout()
            }
            .modifier(PagedScrollStyle(
                scrolledPageID: $scrolledPageID,
                pageWidth: $pageWidth,
                scrollProgress: $scrollProgress,
                pageCount: 2
            ))
            chevron
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { chevronFrame = $0 }
        }
    }

    //Static label (text + chevron) for the overlay/dismiss copies and the compact button.
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
            .lineLimit(2)
            .multilineTextAlignment(.trailing)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { messageHeight = $0 }
            .transition(.opacity.animation(.smooth(duration: 0.2)))
            .fixedSize(horizontal: false, vertical: true)
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
            .dropdownCustomMenuFooterPlatter(corners: corners)    //own the glass platter so the press scales it
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
