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

    private var activeIndex: Int {
        guard !times.isEmpty else { return 0 }
        return min(max(scrolledPageID ?? 0, 0), times.count - 1)
    }

    private var contentFrame: CGRect { times.isEmpty ? chooseTimeFrame : activeTimeFrame }

    private var morphAnchor: CGRect? {
        guard chevronFrame != .zero else {
            return contentFrame == .zero ? nil : contentFrame
        }
        return contentFrame == .zero ? chevronFrame : contentFrame.union(chevronFrame)
    }

    var body: some View {
        HStack {
            rowTitle.opacity(ui.typePopupOpenDelayed ? 0.3 : 1)
            Spacer()
            timeCustomMenu.opacity(ui.typePopupOpenDelayed ? 0 : 1)
        }
        .overlay(alignment: .bottom) {
//            pageIndicator.opacity(ui.typePopupOpenDelayed ? 0 : 1)
        }
        // Warms the wheel-picker machinery off the tap path so the menu's pickers
        // (the expensive UIKit bit) are already hot when it first opens — that's what
        // lets SelectTimeView ride the bloom and fade in without a build hitch.
        .background { pickerWarmUp }

        .transition(.opacity.animation(.smooth(duration: 0.2)))
    }
}

private extension InviteTimeRow {

    // Hidden + inert: pays UIPickerView's one-time, process-wide setup cost up front.
    var pickerWarmUp: some View {
        HStack(spacing: 0) {
            Picker("", selection: .constant(0)) { Text("0").tag(0) }
            Picker("", selection: .constant(0)) { Text("0").tag(0) }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(width: 1, height: 1)
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    var timeCustomMenu: some View {
        // Approximate size of SelectTimeView's platter (day grid width + wheel
        // pickers). Lets the lens bloom on the very first tap before the heavy
        // content is built; the live measure corrects it (masked while the content
        // is still invisible early in the bloom) and caches the exact size after.
        TimeCustomMenu(morphAnchor: morphAnchor,
                       estimatedContentSize: CGSize(width: 320, height: 270),
                       onOpen: openMenu, onClose: closeMenu) {
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
            AnimatedPageIndicator(count: times.count, progress: scrollProgress, inactiveDotSize: 5, activeWidth: 8)
                .scaleEffect(0.6, anchor: .bottom)
                .padding(.bottom, 6)
                .offset(x: 6)
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

    func snapToActivePage() {
        let count = draft.dates.count
        guard count > 0 else { return }
        let target = min(max(scrolledPageID ?? 0, 0), count - 1)
        var tx = Transaction()
        tx.disablesAnimations = true
        withTransaction(tx) { scrolledPageID = target }
    }
    
    //Done this way for smooth transition
    private var rowTitle: some View {
        ZStack(alignment: .leading) {
            Text(rowTitleText().capitalized)
                .font(.body(13, .regular))
                .foregroundStyle(Color(red: 0.70, green: 0.70, blue: 0.75))
                .contentTransition(.numericText())
                .id(rowTitleTransitionID)
                .transition(.blurReplace)
        }
        .animation(.snappy(duration: 0.32, extraBounce: 0), value: rowTitleTransitionID)
        .animation(.snappy, value: scrolledPageID)
    }
    
    private var rowTitleTransitionID: String {
        scrolledPageID == nil || scrolledPageID == 0 ? "when" : "option"
    }
    
    
    func rowTitleText() -> String {
        if scrolledPageID == nil || scrolledPageID == 0 {
            return "When"
        } else {
            return "Option \((scrolledPageID ?? 0) + 1)"
        }
    }
}

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
            //Text's line box reserves descender space below the baseline, so the time's
            //glyphs sit ~1pt above the HStack's geometric center; nudge the chevron up to match.
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

    //scrollProgress is the fractional page index (0, 1, 2…); it lands on a whole
    //number only when settled, so any offset from that means a drag is in flight.
    private var isScrolling: Bool {
        abs(scrollProgress - scrollProgress.rounded()) > 0.01
    }

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
        //Leading fade only mid-drag; settles to 0 on every stationary page so it never covers a time.
        .customHorizontalScrollFade(width: isScrolling ? 40 : 0, showFade: true)
        .customHorizontalScrollFade(width: 12, showFade: true, fromLeading: false)
        .scrollDisabled(times.count <= 1)
    }

    private func page(_ time: Date, isActive: Bool) -> some View {
        Text(FormatEvent.dayAndTime(time, wide: true, withHour: true))
            .font(.body(17, .medium))
            .lineLimit(1)
            .background { if isActive { GlobalFrameReader(frame: $activeTimeFrame) } }
            .frame(width: pageWidth, alignment: .trailing)
    }
}

private struct GlobalFrameReader: View {
    @Binding var frame: CGRect
    var body: some View {
        Color.clear
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
    }
}

extension EnvironmentValues {
    @Entry var isLiveTimeRow: Bool = false
}
