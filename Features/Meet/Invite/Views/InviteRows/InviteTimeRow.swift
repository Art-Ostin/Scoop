//
//  InviteTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTimeRow: View {

    @Bindable var ui: TimeAndPlaceUIState
    @Binding var proposedTimes: ProposedTimes

    //Edited live inside the open menu; committed to `proposedTimes` on dismiss.
    @State private var draft = ProposedTimes()

    @State private var pageWidth: CGFloat = 0
    @State private var scrollProgress: Double = 0
    @State private var scrolledPageID: Int?
    @State private var activeTimeFrame: CGRect = .zero   //active time page (when populated)
    @State private var chooseTimeFrame: CGRect = .zero   //"Choose Time" (when empty)
    @State private var chevronFrame: CGRect = .zero

    private var times: [Date] { proposedTimes.dates.map(\.date) }

    //The visible page, clamped into range.
    private var activeIndex: Int {
        guard !times.isEmpty else { return 0 }
        return min(max(scrolledPageID ?? 0, 0), times.count - 1)
    }

    //Tight frame of whatever the label shows now (a time page, or "Choose Time").
    //Kept in separate state per case so a stale value from one never leaks into the
    //other while switching between them.
    private var contentFrame: CGRect { times.isEmpty ? chooseTimeFrame : activeTimeFrame }

    //Rect the menu's lens collapses to / blooms from: the shown content + chevron.
    //If the content frame isn't measured yet (e.g. just switched from "Choose Time"
    //to times) fall back to the chevron so the lens stays trailing, not centred.
    private var morphAnchor: CGRect? {
        guard chevronFrame != .zero else {
            return contentFrame == .zero ? nil : contentFrame
        }
        return contentFrame == .zero ? chevronFrame : contentFrame.union(chevronFrame)
    }

    var body: some View {
        HStack {
            inviteTypeText(.when)
            Spacer()
            timeCustomMenu.overlay(alignment: .bottom) { pageIndicator }
        }
        .transition(.opacity.animation(.smooth(duration: 0.2)))
    }
}

private extension InviteTimeRow {

    var timeCustomMenu: some View {
        TimeCustomMenu(morphAnchor: morphAnchor, onOpen: openMenu, onClose: closeMenu) {
            SelectTimeView(proposedTimes: $draft).zIndex(2)
        } label: {
            TimeRowMenuLabel(
                times: times,
                activeIndex: activeIndex,
                pageWidth: $pageWidth,
                scrollProgress: $scrollProgress,
                scrolledPageID: $scrolledPageID,
                activeTimeFrame: $activeTimeFrame,
                chooseTimeFrame: $chooseTimeFrame,
                chevronFrame: $chevronFrame
            )
        }
        .environment(\.isLiveTimeRow, true)
    }

    @ViewBuilder
    var pageIndicator: some View {
        if times.count > 1 {
            AnimatedPageIndicator(count: times.count, progress: scrollProgress)
                .scaleEffect(0.6, anchor: .bottom)
                .padding(.bottom, 8)
        }
    }

    func openMenu() {
        draft = proposedTimes
        ui.timePopupOpen = true
    }

    func closeMenu() {
        proposedTimes = draft
        ui.timePopupOpen = false
        snapToActivePage()
    }

    //Snap (instantly) to the page we zoomed in on, or the last one if it's gone,
    //so the row reappears under the lens in the right place.
    func snapToActivePage() {
        let count = draft.dates.count
        guard count > 0 else { return }
        let target = min(max(scrolledPageID ?? 0, 0), count - 1)
        var tx = Transaction()
        tx.disablesAnimations = true
        withTransaction(tx) { scrolledPageID = target }
    }
}

//The menu's trigger. In the row it's the live pager; in the menu's morph overlay
//(`isLive == false`) it's just the active time + chevron, so the lens zooms around
//that alone instead of the whole pager.
private struct TimeRowMenuLabel: View {

    let times: [Date]
    let activeIndex: Int
    @Binding var pageWidth: CGFloat
    @Binding var scrollProgress: Double
    @Binding var scrolledPageID: Int?
    @Binding var activeTimeFrame: CGRect
    @Binding var chooseTimeFrame: CGRect
    @Binding var chevronFrame: CGRect

    @Environment(\.isLiveTimeRow) private var isLive

    private var contentFrame: CGRect { times.isEmpty ? chooseTimeFrame : activeTimeFrame }

    var body: some View {
        if isLive { liveLabel } else { collapsedLabel }
    }

    private var liveLabel: some View {
        HStack(spacing: times.isEmpty ? 12 : 0) {
            if times.isEmpty {
                chooseTimeText
                    .background { GlobalFrameReader(frame: $chooseTimeFrame) }
                    .padding(.vertical, 30)
            } else {
                pager
            }
            chevron
        }
    }

    //Re-laid at the row's on-screen text→chevron gap so it matches the morph anchor.
    private var collapsedLabel: some View {
        HStack(spacing: collapsedGap) {
            activeTimeText
            DropDownButton(isOpen: false)
        }
    }

    private var pager: some View {
        TimeRowScrollLabel(
            times: times,
            activeIndex: activeIndex,
            pageWidth: $pageWidth,
            scrollProgress: $scrollProgress,
            scrolledPageID: $scrolledPageID,
            activeTimeFrame: $activeTimeFrame
        )
    }

    private var chevron: some View {
        DropDownButton(isOpen: false)
            .background { GlobalFrameReader(frame: $chevronFrame) }
    }

    @ViewBuilder
    private var activeTimeText: some View {
        if times.indices.contains(activeIndex) {
            Text(FormatEvent.dayAndTime(times[activeIndex], wide: true, withHour: true))
                .font(.body(17, .medium))
        } else {
            chooseTimeText
        }
    }

    private var collapsedGap: CGFloat {
        guard contentFrame != .zero, chevronFrame != .zero else { return 0 }
        return max(0, chevronFrame.minX - contentFrame.maxX)
    }

    private var chooseTimeText: some View {
        Text("Choose Time")
            .kerning(0.32)
            .font(.body(16, .regular))
            .foregroundStyle(Color(white: 0.4))
            .transition(.opacity.animation(.smooth(duration: 0.2)))
    }
}

private struct TimeRowScrollLabel: View {

    let times: [Date]
    let activeIndex: Int
    @Binding var pageWidth: CGFloat
    @Binding var scrollProgress: Double
    @Binding var scrolledPageID: Int?
    @Binding var activeTimeFrame: CGRect

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(times.enumerated()), id: \.offset) { idx, time in
                    page(time, isActive: idx == activeIndex)
                }
            }
            .offset(x: -12) //Align with the rest of the content
            .padding(.vertical, 30)
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrolledPageID)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { pageWidth = $0 }
        .trackScrollProgress(scrollProgress: $scrollProgress)
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        //Leading fade only while scrolling, so it doesn't cover a stationary time.
        .customHorizontalScrollFade(width: scrollProgress == 0 ? 0 : 40, showFade: true)
        .customHorizontalScrollFade(width: 12, showFade: true, fromLeading: false)
        .scrollDisabled(times.count <= 1)
    }

    //lineLimit(1) so a momentarily-zero pageWidth (during the open re-layout) can't
    //wrap the text and balloon the scroll height under the floating Hide button.
    private func page(_ time: Date, isActive: Bool) -> some View {
        Text(FormatEvent.dayAndTime(time, wide: true, withHour: true))
            .font(.body(17, .medium))
            .lineLimit(1)
            .background { if isActive { GlobalFrameReader(frame: $activeTimeFrame) } }
            .frame(width: pageWidth, alignment: .trailing)
    }
}

//Publishes a view's global frame into `frame`.
private struct GlobalFrameReader: View {
    @Binding var frame: CGRect
    var body: some View {
        Color.clear
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
    }
}

extension EnvironmentValues {
    //True only in the row's own copy of the label, not the menu's morph overlay copy.
    @Entry var isLiveTimeRow: Bool = false
}
