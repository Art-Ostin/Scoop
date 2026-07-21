//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTypeRow: View {

    //Injected
    @Bindable var ui: TimeAndPlaceUIState
    @Binding var type: Event.EventType
    @Binding var unparsedMessage: String?
    @Binding var showMessageScreen: Bool

    //Local view state — messageBeforeEdit: snapshot when the editor opens, to tell if it changed on close
    @State private var messageBeforeEdit: String?

    @State private var openInfoTypes: Set<Event.EventType> = []
    @State private var typePulse = false

    @State private var scrollProgress: Double = 0
    @State private var scrolledPageID: Int?

    //Global frames feeding the menu's morph anchor.
    @State private var typeFrame: CGRect = .zero
    @State private var messageFrame: CGRect = .zero
    @State private var chevronFrame: CGRect = .zero

    private let menuCorners = RectangleCornerRadii(top: 20, bottom: 6)
    private let footerCorners = RectangleCornerRadii(top: 6, bottom: 18)

    private var message: String {
        (unparsedMessage ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var onMessagePage: Bool {
        !message.isEmpty && (scrolledPageID ?? 0) >= 1
    }

    private var showsPageIndicator: Bool { !message.isEmpty }
    private var rowHeight: CGFloat { InviteRowMetrics.rowHeight(showsIndicator: showsPageIndicator) }
    private var primaryContentOffset: CGFloat {
        -(InviteRowMetrics.contentHeight(showsIndicator: showsPageIndicator)
          - InviteRowMetrics.singleLineContentHeight) / 2
    }

    @State var showTypeInfoScreen = false
    
    var body: some View {
        //The message page sits a touch closer to the title than the type page.
        HStack(spacing: scrolledPageID == 1 ? 2 : 4) {
            rowTitle
                .frame(height: InviteRowMetrics.primaryLineHeight)
                .offset(y: primaryContentOffset)
            Spacer(minLength: 0)
            typeMenu
        }
        .frame(height: rowHeight)
        .overlay(alignment: .bottomTrailing) {
            pageIndicator
                .padding(.trailing, 16)
                .padding(.bottom, InviteRowMetrics.verticalPadding)
        }
        .onChange(of: type) { if onMessagePage { pulseTypeTitle() } }
        .onChange(of: showMessageScreen) { messageScreenChanged() }
        .blurPop(visible: !ui.delayedTimePopupOpen, scale: 1)
    }
}

//The dropdown menu and what anchors it
extension InviteTypeRow {

    private var typeMenu: some View {
        DropdownCustomMenu(
            cornerRadii: menuCorners,
            footerCornerRadii: footerCorners,
            morphsFromTrailingPoint: onMessagePage,
            morphAnchor: morphAnchor,
            flexOnEmptyDismiss: true, //no type change flexes the label instead of morphing
            placementOffsetX: -6,
            placementOffsetY: 24,
            onOpen: { ui.activePopup = .type },
            onClose: { ui.activePopup = nil; openInfoTypes.removeAll() },
            onLabelTap: handleLabelTap,
            footer: { AnyView(addMessageFooter) },
            content: { selectTypeView },
            label: { menuLabel }
        )
        .environment(\.isLiveInviteRow, true)
    }

    private var menuLabel: some View {
        TypeRowMenuLabel(
            type: type,
            message: message,
            ui: ui,
            showMessageScreen: showMessageScreen,
            scrollProgress: $scrollProgress,
            scrolledPageID: $scrolledPageID,
            typeFrame: $typeFrame,
            messageFrame: $messageFrame,
            chevronFrame: $chevronFrame,
            rowHeight: rowHeight,
            primaryContentOffset: primaryContentOffset
        )
    }

    //Union of the active content page and the chevron, ignoring frames not yet measured.
    private var morphAnchor: CGRect? {
        let content = onMessagePage ? messageFrame : typeFrame
        let union = [content, chevronFrame].filter { $0 != .zero }.reduce(CGRect.null) { $0.union($1) }
        return union.isNull ? nil : union
    }

    //A tap while parked on the message page (id 1) opens the message editor instead of the menu —
    //including the empty "Add Message" placeholder. The type page (id 0) falls through to the menu.
    private func handleLabelTap() -> Bool {
        guard (scrolledPageID ?? 0) >= 1 else { return false }
        showMessageScreen = true
        return true
    }

    private var selectTypeView: some View {
        SelectTypeView(
            openTypes: $openInfoTypes,
            selectedType: $type,
            showMessageScreen: $showMessageScreen,
            message: message,
            onMessagePage: onMessagePage
        )
    }

    private var addMessageFooter: some View {
        AddMessageFooter(message: message, corners: footerCorners) {
            showMessageScreen = true
        }
    }

    @ViewBuilder
    private var pageIndicator: some View {
        if !message.isEmpty {
            InvitePageIndicator(count: 2, progress: scrollProgress)
        }
    }
}

//Row title: "WHAT" caption ↔ selected type swap
extension InviteTypeRow {

    //ZStack + the .animation(value:) modifiers form a stable ancestor for the .id swap;
    //without one the .blurReplace transition rebuilds and swaps instantly.
    private var rowTitle: some View {
        let isTypeOpen = ui.isPopupOpen(.type)
        return ZStack(alignment: .leading) {
            Group {
                if onMessagePage {
                    Text(type.title.capitalized)
                        .font(.body(isTypeOpen ? 15 : 13, .regular))
                        .foregroundStyle(isTypeOpen ? Color.textPrimary : Color.textTertiary)
                } else {
                    Text("What")
                        .font(.body(15, isTypeOpen ? .medium : .regular))
                        .foregroundStyle(isTypeOpen ? Color.textPrimary : Color.textTertiary)
                        .scaleEffect(isTypeOpen ? 1 : 0.8, anchor: .leading)
                        .animation(.smooth(duration: 0.2), value: isTypeOpen)
                        .shrinkPress {showTypeInfoScreen = true}
                }
            }
            .multilineTextAlignment(.leading) //so "Double Date" stays on one line
            .frame(width: 50, alignment: .leading)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .id(rowTitleTransitionID)
            .transition(.blurReplace)
        }
        .scaleEffect(typePulse ? DropdownCustomMenuSpec.flexScale : 1, anchor: .leading)
        .offset(y: typePulse ? DropdownCustomMenuSpec.flexOffsetY : 0)
        .animation(typePulse ? DropdownCustomMenuSpec.flexUp : DropdownCustomMenuSpec.flexDown, value: typePulse)
        .animation(.transition, value: rowTitleTransitionID)
        .animation(.transition, value: scrolledPageID)
        .sheet(isPresented: $showTypeInfoScreen) {
            Text("Type Info Here")
        }

    }

    private var rowTitleTransitionID: String { onMessagePage ? "type-\(type.title)" : "what" }

    //Echoes the menu's `.flex` dismiss on the title when a type is picked from the message page.
    private func pulseTypeTitle() {
        typePulse = true
        Task {
            try? await Task.sleep(for: .seconds(DropdownCustomMenuSpec.flexHold))
            typePulse = false
        }
    }

}

//Message bookkeeping: editor round-trips
extension InviteTypeRow {

    //Editor opened: snapshot the message. Editor closed: if it changed, park the pager on it.
    private func messageScreenChanged() {
        if showMessageScreen {
            messageBeforeEdit = unparsedMessage
        } else if unparsedMessage != messageBeforeEdit, !message.isEmpty {
            withAnimation(.move) { scrolledPageID = 1 }
        }
    }

}

//The menu's label: the live type/message pager in the row, or the collapsed form the morph carries.
private struct TypeRowMenuLabel: View {

    let type: Event.EventType
    let message: String
    let ui: TimeAndPlaceUIState
    let showMessageScreen: Bool
    @Binding var scrollProgress: Double
    @Binding var scrolledPageID: Int?
    @Binding var typeFrame: CGRect
    @Binding var messageFrame: CGRect
    @Binding var chevronFrame: CGRect
    let rowHeight: CGFloat
    let primaryContentOffset: CGFloat

    @Environment(\.isLiveInviteRow) private var isLive

    //Local to the live pager — the parent never reads it.
    @State private var pageWidth: CGFloat = 0
    @State private var showScrollFades = false
    var body: some View {
        if isLive { liveLabel } else { collapsedLabel }
    }

    private var liveLabel: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    typeText
                        .getRect($typeFrame)
                        .frame(height: InviteRowMetrics.primaryLineHeight)
                        .frame(width: pageWidth, alignment: .trailing)
                        .offset(y: primaryContentOffset)
                        .id(0)

                    messageView
                        .getRect($messageFrame)
                        .padding(.leading, Spacing.sm)
                        .frame(width: pageWidth, alignment: .trailing)
                        .offset(y: primaryContentOffset)
                        .id(1)
                }
                .offset(x: -Spacing.sm) //Align with the rest of the content
                .frame(height: rowHeight)
                .scrollTargetLayout()
            }
            .frame(height: rowHeight)
            .contentShape(Rectangle())
            .scrollClipDisabled()
            .modifier(PagedScrollStyle(
                scrolledPageID: $scrolledPageID,
                pageWidth: $pageWidth,
                scrollProgress: $scrollProgress,
                pageCount: 2
            ))
            .onScrollPhaseChange { _, phase in
                showScrollFades = phase.isScrolling && phase != .tracking
            }
            .customHorizontalScrollFade(width: showScrollFades ? 40 : 0, showFade: true)
            .customHorizontalScrollFade(width: showScrollFades ? 12 : 0, showFade: true, fromLeading: false)
            .animation(.quick, value: showScrollFades)
            chevron
                .getRect($chevronFrame)
                .offset(y: primaryContentOffset)
        }
    }

    private var collapsedLabel: some View {
        HStack(spacing: Spacing.sm) {
            typeText
            chevron
        }
        .geometryGroup()
        .contentTransition(.opacity)
    }

    private var typeText: some View {
        Text(type.longTitle)
            .font(.body(17, .medium))
            .lineLimit(1)
            .contentTransition(.opacity)
    }

    private var chevron: some View {
        DropDownButton(isOpen: ui.isPopupOpen(.type) || showMessageScreen)
    }

    @ViewBuilder
    private var messageView: some View {
        if !message.isEmpty {
            Text(message)
                .font(.body(12, .regular))
                .foregroundStyle(Color.textTertiary)
                .lineLimit(3)
                .multilineTextAlignment(.trailing)
                .lineSpacing(InviteRowMetrics.messageLineSpacing)
                .transition(.opacity.animation(.transition))
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: InviteRowMetrics.primaryLineHeight, alignment: .bottom)
        } else {
            Text("Add Message")
                .font(.body(16, .regular))
                .foregroundStyle(Color.textSecondary)
                .frame(height: InviteRowMetrics.primaryLineHeight)
                .transition(.opacity.animation(.transition))
        }
    }
}

//Own struct: renders in the menu's overlay window, where the dismiss env would otherwise no-op.
private struct AddMessageFooter: View {

    @Environment(\.dropdownCustomMenuDismiss) private var menuDismiss

    let message: String
    let corners: RectangleCornerRadii
    let onSelect: () -> Void

    var body: some View {
        Text(message.isEmpty ? "Add a Message" : "Edit Message")
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.body(16, .bold))
            .kerning(0.5)
            .frame(height: 40)
            .frame(width: SelectTypeView.cardWidth, alignment: .leading)
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
