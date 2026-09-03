//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

/*
 
 import SwiftUI

 //How far the row's title, value and chevron lift while the type menu is open.
 private let openLift: CGFloat = -4

 //Geometry: the value and chevron slide left by this while the type menu is open — paired with
 //openLift on y, so the two must move together or they drift apart mid-open.
 private let openShiftX: CGFloat = -20

 struct InviteTypeRow2: View {
     //Injected
     var ui: TimeAndPlaceUIState
     @Binding var type: Event.EventType
     @Binding var unparsedMessage: String?
     @Binding var showMessageScreen: Bool

     //Local view state — messageBeforeEdit: snapshot when the editor opens, to tell if it changed on close
     @State private var messageBeforeEdit: String?

     @State private var openInfoTypes: Set<Event.EventType> = []

     //Set by a tap on the "What" caption, which sits outside the menu's label.
     @State private var openTypeMenu = false

     @State private var scrollProgress: Double = 0
     @State private var scrolledPageID: Int?

     //Global frames feeding the menu's morph anchor.
     @State private var typeFrame: CGRect = .zero
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

     //The indicator steps aside while this row's own menu is up (delayed to sync with its platter bloom).
     private var typePopupOpen: Bool { ui.isPopupOpenDelayed(.type) }

     private var rowHeight: CGFloat {
         InviteRowMetrics.rowHeight(showsIndicator: showsPageIndicator)
     }
     private var primaryContentOffset: CGFloat {
         InviteRowMetrics.primaryContentOffset(showsIndicator: showsPageIndicator)
     }

     var body: some View {
         //The message page sits a touch closer to the title than the type page.
         HStack(spacing: scrolledPageID == 1 ? 2 : 4) {
             rowTitle
                 .frame(height: InviteRowMetrics.primaryLineHeight)
                 .offset(y: showsPageIndicator ? InviteRowMetrics.indicatorCaptionOffset : 0)
             Spacer(minLength: 0)
             typeMenu
         }
         .frame(height: rowHeight)
         .overlay(alignment: .bottomTrailing) {
             pageIndicator
                 .padding(.trailing, 16)
                 .padding(.bottom, InviteRowMetrics.bottomPadding(showsIndicator: showsPageIndicator))
                 .opacityPop(visible: !typePopupOpen)
                 .animation(.transition, value: typePopupOpen) //opacityPop carries no curve of its own
         }
         .onChange(of: showMessageScreen) { messageScreenChanged() }
         .onChange(of: message.isEmpty) { _, isEmpty in messageEmptied(isEmpty) }
         .blurPop(visible: !ui.delayedTimePopupOpen, scale: 1)
     }
 }

 //The dropdown menu and what anchors it
 extension InviteTypeRow {

     private var typeMenu: some View {
         DropdownCustomMenu(
             cornerRadii: menuCorners,
             morphAnchor: morphAnchor,
             placementOffsetX: -12,
             placementOffsetY: 28,
             onOpen: { ui.activePopup = .type },
             onClose: { ui.activePopup = nil; openInfoTypes.removeAll() },
             onLabelTap: handleLabelTap,
             openRequest: $openTypeMenu,
             message: message,
             showMessageScreen: $showMessageScreen,
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
             chevronFrame: $chevronFrame,
             rowHeight: rowHeight,
             primaryContentOffset: primaryContentOffset
         )
     }

     //Union of the type page and the chevron, ignoring frames not yet measured. The menu can only
     //ever present from the type page — `handleLabelTap` claims every tap on the message page.
     private var morphAnchor: CGRect? {
         let union = [typeFrame, chevronFrame].filter { $0 != .zero }.reduce(CGRect.null) { $0.union($1) }
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
             message: message
         )
     }


     @ViewBuilder
     private var pageIndicator: some View {
         if showsPageIndicator {
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
             whatTitle(isOpen: isTypeOpen)

             //Only the type name still swaps identity (it changes per type), so it alone
             //keeps the .id + .blurReplace pair.
             if onMessagePage {
                 Text(type.title.capitalized)
                     .font(.body(isTypeOpen ? 15 : 13, .regular))
                     .foregroundStyle(isTypeOpen ? Color.textPrimary : Color.textTertiary)
                     .inviteRowTitleColumn()
                     .id(rowTitleTransitionID)
                     .transition(.blurReplace)
             }
         }
         .animation(.transition, value: rowTitleTransitionID)
         .animation(.transition, value: scrolledPageID)
     }

     private func whatTitle(isOpen: Bool) -> some View {
         Text("What")
             .font(.title(17, .medium))
             .foregroundStyle(isOpen ? Color.textPrimary : Color.textTertiary)
             .inviteRowTitleColumn()
             .offset(x: isOpen ? 24 : 0, y: isOpen ? openLift + openCaptionLift : 0)
             .scaleEffect(isOpen ? 1 : 0.765, anchor: .leading) //Geometry: 13/17 — collapsed reads as 13pt
             .animation(.smooth(duration: 0.2), value: isOpen)
             .opacity(onMessagePage ? 0 : 1)
             .blur(radius: onMessagePage ? 6 : 0) //the .blurReplace look, without a second copy
             .allowsHitTesting(!onMessagePage)
             .shrinkPress { openTypeMenu = true }
     }

     //Geometry: with a message the row grows for the indicator and the caption rides 2pt lower, while
     //the value rides primaryContentOffset up — open, the caption trades the one for the other so the
     //two sit on the same line instead of the caption hanging into the platter.
     private var openCaptionLift: CGFloat {
         showsPageIndicator ? primaryContentOffset - InviteRowMetrics.indicatorCaptionOffset : 0
     }

     private var rowTitleTransitionID: String { onMessagePage ? "type-\(type.title)" : "what" }
 }

 //Message bookkeeping: editor round-trips
 extension InviteTypeRow {

     private func messageScreenChanged() {
         if showMessageScreen {
             messageBeforeEdit = unparsedMessage
         } else if unparsedMessage != messageBeforeEdit, !message.isEmpty {
             withAnimation(.move) { scrolledPageID = 1 }
         }
     }

     private func messageEmptied(_ isEmpty: Bool) {
         guard isEmpty, (scrolledPageID ?? 0) >= 1 else { return }
         withAnimation(.move) { scrolledPageID = 0 }
     }

 }

 //The title column both states share: one line, pinned width, shrink rather than wrap.
 private extension View {
     func inviteRowTitleColumn() -> some View {
         multilineTextAlignment(.leading) //so "Double Date" stays on one line
             .frame(width: 50, alignment: .leading)
             .lineLimit(1)
             .minimumScaleFactor(0.75)
     }

     //The lift the value and the chevron ride while the type menu is open. Both wear it so they
     //travel as one — the title's own lift differs (it shifts the other way and scopes its scale).
     func typeMenuOpenLift(_ isOpen: Bool) -> some View {
         offset(x: isOpen ? openShiftX : 0, y: isOpen ? openLift : 0)
             .animation(.smooth(duration: 0.2), value: isOpen)
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
     @Binding var chevronFrame: CGRect
     let rowHeight: CGFloat
     let primaryContentOffset: CGFloat

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
                     liveTypeText
                         .getRect($typeFrame)
                         .frame(height: InviteRowMetrics.primaryLineHeight)
                         .frame(width: pageWidth, alignment: .trailing)
                         .offset(y: primaryContentOffset)
                         .id(0)
                         .typeMenuOpenLift(ui.isPopupOpen(.type))

                     messageView
                         .padding(.leading, Spacing.sm)
                         .frame(width: pageWidth, alignment: .trailing)
                         .offset(y: primaryContentOffset)
                         .id(1)
                 }
                 .offset(x: -InviteRowMetrics.valueChevronSpacing) //Align with the rest of the content
                 .frame(height: rowHeight)
                 .scrollTargetLayout()
             }
             .frame(height: rowHeight)
             .contentShape(Rectangle())
             .modifier(PagedScrollStyle(
                 scrolledPageID: $scrolledPageID,
                 pageWidth: $pageWidth,
                 scrollProgress: $scrollProgress,
                 pageCount: 2
             ))
             chevron
                 .typeMenuOpenLift(ui.isPopupOpen(.type))
                 .getRect($chevronFrame)
                 .offset(y: primaryContentOffset)
         }
     }

     //The copy the menu morph carries keeps the plain crossfade, so the platter dismiss
     //doesn't animate the name a second time on its own curve.
     private var collapsedLabel: some View {
         HStack(spacing: InviteRowMetrics.valueChevronSpacing) {
             typeName
             chevron
         }
         .geometryGroup()
         .contentTransition(.opacity)
     }

     private var liveTypeText: some View {
         //Must go in ZSTack for blur replace works
         ZStack(alignment: .trailing) {
             typeName
                 .id(type)
                 .transition(.blurReplace)
         }
         .animation(.dissolve, value: type)
     }

     private var typeName: some View {
         Text(type.longTitle)
             .font(.body(17, .medium))
             .lineLimit(1)
     }

     //Bare — no open lift. The menu freezes/carries the COLLAPSED copy as a flat bitmap, and
     //a lift baked in there shoved the chevron 20pt onto the text tail during the dismiss
     //morph. The live pager applies the lift at its call site instead.
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
 */


//Own struct: renders in the menu's overlay window, where the dismiss env would otherwise no-op.
