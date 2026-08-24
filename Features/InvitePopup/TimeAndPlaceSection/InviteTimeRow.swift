//
//  InviteTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTimeRow: View {

    //Injected
    var ui: TimeAndPlaceUIState
    @Binding var proposedTimes: ProposedTimes

    //Local view state — draft is edited live inside the open menu; committed to `proposedTimes` on dismiss
    @State private var draft = ProposedTimes()
    @State private var scrollProgress: Double = 0
    @State private var scrolledPageID: Int?

    //Set by a tap on the "When" caption, which sits outside the menu's label.
    @State private var openTimeMenu = false

    //Global frames feeding the menu's morph anchor.
    @State private var activeTimeFrame: CGRect = .zero   //active time page (when populated)
    @State private var chooseTimeFrame: CGRect = .zero   //"Choose Time" (when empty)
    @State private var chevronFrame: CGRect = .zero

    private var times: [Date] { proposedTimes.dates.map(\.date) }
    private var showsPageIndicator: Bool { times.count > 1 }
    private var rowHeight: CGFloat { InviteRowMetrics.rowHeight(showsIndicator: showsPageIndicator) }
    private var primaryContentOffset: CGFloat {
        InviteRowMetrics.primaryContentOffset(showsIndicator: showsPageIndicator)
    }

    //Hidden while the type menu is open (delayed to sync with its platter bloom).
    private var typePopupOpen: Bool { ui.isPopupOpenDelayed(.type) }

    var body: some View {
        HStack {
            rowTitle
                .frame(height: InviteRowMetrics.primaryLineHeight)
                .offset(y: showsPageIndicator ? InviteRowMetrics.indicatorCaptionOffset : 0)
            Spacer()
            timeMenu.opacity(typePopupOpen ? 0 : 1)
        }
        .frame(height: rowHeight)
        .overlay(alignment: .bottomTrailing) {
            pageIndicator
                .padding(.trailing, 16)
                .padding(.bottom, InviteRowMetrics.bottomPadding(showsIndicator: showsPageIndicator))
                .opacity(typePopupOpen ? 0 : 1)
        }
        .background { TimePickerWarmUp() }
        .onChange(of: times.count) { _, count in
            if count == 0 { scrolledPageID = 0 }
        } //So goes to 1 on clear
        .transition(.opacity.animation(.transition))
    }
}

//The time menu and what anchors it
extension InviteTimeRow {

    private var timeMenuWidth: CGFloat { 325 }

    private var timeMenu: some View {

        VStack(alignment: .trailing, spacing: 0) {
            
            TimeCustomMenu(morphAnchor: morphAnchor,
                           estimatedContentSize: CGSize(width: timeMenuWidth, height: 286), //SelectTimeView at rest: 16 + 34 title row + 16 + 12 header + 4 + 80 grid + 4 + 120 wheel
                           verticalPlacement: .below, //The designed spot: centered over the card's rows
                           placementOffsetX: TimeCustomMenuSpec.placementOffsetX - 24,
                           placementOffsetY: TimeCustomMenuSpec.placementOffsetY,
                           openRequest: $openTimeMenu,
                           onOpen: openMenu, onClose: closeMenu) {
                SelectTimeView(proposedTimes: $draft)
                    .frame(width: timeMenuWidth)
                    .zIndex(2)
            } label: {
                TimeRowMenuLabel(
                    times: times,
                    scrollProgress: $scrollProgress,
                    scrolledPageID: $scrolledPageID,
                    activeTimeFrame: $activeTimeFrame,
                    chooseTimeFrame: $chooseTimeFrame,
                    chevronFrame: $chevronFrame,
                    rowHeight: rowHeight,
                    primaryContentOffset: primaryContentOffset,
                    pagerDisabled: ui.isPopupOpen(.time)
                )
            }
            .environment(\.isLiveInviteRow, true)
        }
    }

    //Union of the active content and the chevron, ignoring frames not yet measured.
    private var morphAnchor: CGRect? {
        let content = times.isEmpty ? chooseTimeFrame : activeTimeFrame
        let union = [content, chevronFrame].filter { $0 != .zero }.reduce(CGRect.null) { $0.union($1) }
        return union.isNull ? nil : union
    }

    private func openMenu() {
        draft = proposedTimes
        ui.activePopup = .time
    }

    private func closeMenu() {
        proposedTimes = draft
        ui.activePopup = nil
        snapToActivePage()
    }

    private func snapToActivePage() {
        let count = draft.dates.count
        guard count > 0 else { return }
        let target = min(max(scrolledPageID ?? 0, 0), count - 1)
        var tx = Transaction()
        tx.disablesAnimations = true
        withTransaction(tx) { scrolledPageID = target }
    }
}

//Row title: "WHEN" ↔ "Option n" swap
extension InviteTimeRow {

    private var rowTitle: some View {
        //Use the ZStack with if else, to get the blur opacity effect
        ZStack(alignment: .leading) {
            Group {
                if isWhenLabel {
                    RowCaption(label: .when)
                } else {
                    Text(optionTitle)
                        .font(.body(13, .regular))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .contentTransition(.numericText())
            .id(rowTitleTransitionID)
            .transition(.blurReplace)
        }
        .animation(.transition, value: rowTitleTransitionID)
        .animation(.transition, value: scrolledPageID)
        .shrinkPress { openTimeMenu = true } //Inside blurPop, so it can't fire while another popup owns the card
        .blurPop(visible: !ui.anyPopupOpenDelayed, scale: 1)
    }

    private var isWhenLabel: Bool { scrolledPageID == nil || scrolledPageID == 0 }

    private var rowTitleTransitionID: String { isWhenLabel ? "when" : "option" }

    private var optionTitle: String { "Option \((scrolledPageID ?? 0) + 1)" }
}

//Row chrome
extension InviteTimeRow {

    @ViewBuilder
    private var pageIndicator: some View {
        if showsPageIndicator {
            InvitePageIndicator(count: times.count, progress: scrollProgress)
        }
    }

}

//The menu's label: the live pager in the row, or the collapsed time the morph carries.
private struct TimeRowMenuLabel: View {

    let times: [Date]
    @Binding var scrollProgress: Double
    @Binding var scrolledPageID: Int?
    @Binding var activeTimeFrame: CGRect
    @Binding var chooseTimeFrame: CGRect
    @Binding var chevronFrame: CGRect
    let rowHeight: CGFloat
    let primaryContentOffset: CGFloat
    //While the time menu is open the same touch that presented it (touch-down open)
    //would keep panning the pager invisibly under the platter — freeze it instead.
    let pagerDisabled: Bool

    @Environment(\.isLiveInviteRow) private var isLive

    //Local to the live pager — the parent never reads it.
    @State private var pageWidth: CGFloat = 0

    private var activeIndex: Int {
        guard !times.isEmpty else { return 0 }
        return min(max(scrolledPageID ?? 0, 0), times.count - 1)
    }

    private var contentFrame: CGRect { times.isEmpty ? chooseTimeFrame : activeTimeFrame }

    var body: some View {
        if isLive { liveLabel } else { collapsedLabel }
    }

    private var liveLabel: some View {
        HStack(spacing: InviteRowMetrics.valueChevronSpacing) {
            valueSlot
            chevron
                .offset(y: primaryContentOffset)
        }
    }

    //Must put the valueSlot in a ZStack with If Else so blur poacity works. 
    private var valueSlot: some View {
        ZStack(alignment: .trailing) {
            Group {
                if times.isEmpty {
                    chooseTimeText
                        .getRect($chooseTimeFrame)
                        .frame(height: rowHeight)
                        .offset(y: primaryContentOffset)
                } else {
                    pager
                }
            }
            .id(times.isEmpty)
            .transition(.blurReplace)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .animation(.dissolve, value: times.isEmpty)
    }

    //Re-laid at the row's on-screen text→chevron gap so it matches the morph anchor.
    private var collapsedLabel: some View {
        HStack(spacing: collapsedGap) {
            activeTimeText
            DropDownButton(isOpen: false)
        }
    }

    private var collapsedGap: CGFloat {
        guard contentFrame != .zero, chevronFrame != .zero else { return 0 }
        return max(0, chevronFrame.minX - contentFrame.maxX)
    }

    private var pager: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(times.enumerated()), id: \.offset) { index, time in
                    page(time, isActive: index == activeIndex)
                }
            }
            .frame(height: rowHeight)
            .scrollTargetLayout()
        }
        .frame(height: rowHeight)
        .scrollDisabled(pagerDisabled)
        .contentShape(Rectangle())
        .modifier(PagedScrollStyle(
            scrolledPageID: $scrolledPageID,
            pageWidth: $pageWidth,
            scrollProgress: $scrollProgress,
            pageCount: times.count
        ))
    }

    private func page(_ time: Date, isActive: Bool) -> some View {
        Text(FormatEvent.shortDayAndTime(time))
            .font(.body(17, .medium))
            .minimumScaleFactor(0.9)
            .lineLimit(1)
            .truncationMode(.middle)
            .background { if isActive { Color.clear.getRect($activeTimeFrame) } }
            .frame(height: InviteRowMetrics.primaryLineHeight)
            .frame(width: pageWidth, alignment: .trailing)
            .offset(y: primaryContentOffset)
    }

    private var chevron: some View {
        DropDownButton(isOpen: false)
            .getRect($chevronFrame)
    }

    @ViewBuilder
    private var activeTimeText: some View {
        if times.indices.contains(activeIndex) {
            Text(FormatEvent.shortDayAndTime(times[activeIndex]))
                .font(.body(17, .medium))
        } else {
            chooseTimeText
        }
    }

    private var chooseTimeText: some View {
        Text("Choose Time")
            .kerning(0.32)
            .font(.body(16, .regular))
            .foregroundStyle(Color.textSecondary)
            .frame(height: InviteRowMetrics.primaryLineHeight)
    }
}
