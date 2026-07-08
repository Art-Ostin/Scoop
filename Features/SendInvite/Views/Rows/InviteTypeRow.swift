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

    //Snapshot of the message when the editor opens, so we can tell if it changed on close.
    @State private var messageBeforeEdit: String?
    @State private var messageHeight: CGFloat = 0
    @State private var lastCountedMessage = ""

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

    var body: some View {
        //The message page sits a touch closer to the title than the type page.
        HStack(spacing: scrolledPageID == 1 ? 2 : 4) {
            rowTitle
            Spacer(minLength: 0)
            typeMenu
        }
        .overlay(alignment: .trailing) {
//            pageIndicator
//                .offset(y: 20)
//                .offset(x: -22)
        }
        .task(id: messageHeight) { updateLineHeight() }        //typing: recount once the new text's height settles
        .onChange(of: message) { updateLineHeight() }          //clearing/edits: recount (and reset) on text change
        .onChange(of: type) { if onMessagePage { pulseTypeTitle() } }
        .onChange(of: ui.showMessageScreen) { messageScreenChanged() }
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

    //A tap while parked on the message page (id 1) opens the message editor instead of the menu —
    //including the empty "Add Message" placeholder. The type page (id 0) falls through to the menu.
    private func handleLabelTap() -> Bool {
        guard (scrolledPageID ?? 0) >= 1 else { return false }
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
}

//Row title: "WHAT" caption ↔ selected type swap
extension InviteTypeRow {

    //ZStack + the .animation(value:) modifiers form a stable ancestor for the .id swap;
    //without one the .blurReplace transition rebuilds and swaps instantly.
    private var rowTitle: some View {
        ZStack(alignment: .leading) {
            Group {
                if onMessagePage {
                    Text(type.title.capitalized)
                        .font(.body(13, .regular))
                        .foregroundStyle(Color.textTertiary)
                } else {
                    RowCaption(label: .what, dimmed: false)
                }
            }
            .multilineTextAlignment(.leading) //so "Double Date" stays on one line
            .frame(width: 47, alignment: .leading)
            .lineSpacing(2)
            .id(rowTitleTransitionID)
            .transition(.blurReplace)
        }
        .scaleEffect(typePulse ? DropdownCustomMenuSpec.flexScale : 1, anchor: .leading)
        .offset(y: typePulse ? DropdownCustomMenuSpec.flexOffsetY : 0)
        .animation(typePulse ? DropdownCustomMenuSpec.flexUp : DropdownCustomMenuSpec.flexDown, value: typePulse)
        .animation(.snappy(duration: 0.32, extraBounce: 0), value: rowTitleTransitionID)
        .animation(.snappy, value: scrolledPageID)
        .opacity(ui.isPopupOpen(.type) ? 0.3 : 1)
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

    private var pageIndicator: some View {
        AnimatedPageIndicator(count: 2, progress: scrollProgress, inactiveDotSize: 5, activeWidth: 8)
            .scaleEffect(0.6, anchor: .bottom)
            .padding(.bottom, 8)
            .offset(x: 6)
            .opacity(ui.isPopupOpen(.type) ? 0 : 1)
    }
}

//Message bookkeeping: editor round-trips and line count
extension InviteTypeRow {

    //Editor opened: snapshot the message. Editor closed: if it changed, park the pager on it.
    private func messageScreenChanged() {
        if ui.showMessageScreen {
            messageBeforeEdit = unparsedMessage
        } else if unparsedMessage != messageBeforeEdit, !message.isEmpty {
            withAnimation(.snappy(duration: 0.3)) { scrolledPageID = 1 }
        }
    }

    private func updateLineHeight() {
        if message.isEmpty {
            ui.messageLineCount = 0
            scrolledPageID = 0
            lastCountedMessage = ""
            return
        }
        guard message != lastCountedMessage, messageHeight > 0 else { return }
        let lineHeight = UIFont.preferredFont(forTextStyle: .footnote).lineHeight
        ui.messageLineCount = min(3, Int((messageHeight / lineHeight).rounded()))
        lastCountedMessage = message
    }
}

//The menu's label: the live type/message pager in the row, or the collapsed form the morph carries.
private struct TypeRowMenuLabel: View {

    let type: Event.EventType
    let message: String
    let ui: TimeAndPlaceUIState
    @Binding var scrollProgress: Double
    @Binding var scrolledPageID: Int?
    @Binding var messageHeight: CGFloat
    @Binding var typeFrame: CGRect
    @Binding var messageFrame: CGRect
    @Binding var chevronFrame: CGRect

    @Environment(\.isLiveInviteRow) private var isLive

    //Local to the live pager — the parent never reads it.
    @State private var pageWidth: CGFloat = 0

    var body: some View {
        if isLive { liveLabel } else { collapsedLabel }
    }

    private var liveLabel: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    typeText
                        .readGlobalFrame(into: $typeFrame)
                        .frame(width: pageWidth, alignment: .trailing)
                        .id(0)

                    messageView
                        .readGlobalFrame(into: $messageFrame)
                        .padding(.leading, 12)
                        .frame(width: pageWidth, alignment: .trailing)
                        .id(1)
                }
                .offset(x: -12) //Align with the rest of the content
                .frame(height: InviteRowMetrics.rowHeight)
                .scrollTargetLayout()
            }
            .modifier(PagedScrollStyle(
                scrolledPageID: $scrolledPageID,
                pageWidth: $pageWidth,
                scrollProgress: $scrollProgress,
                pageCount: 2
            ))
            chevron
                .readGlobalFrame(into: $chevronFrame)
        }
    }

    private var collapsedLabel: some View {
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
        DropDownButton(isOpen: ui.isPopupOpen(.type))
    }

    @ViewBuilder
    private var messageView: some View {
        if !message.isEmpty {
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.trailing)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { messageHeight = $0 }
                .transition(.opacity.animation(.smooth(duration: 0.2)))
                .fixedSize(horizontal: false, vertical: true)
                .offset(y: ui.messageLineCount == 3 ? -4 : 0)
        } else {
            Text("Add Message")
                .font(.body(16, .regular))
                .foregroundStyle(Color.textSecondary)
                .transition(.opacity.animation(.smooth(duration: 0.2)))
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
