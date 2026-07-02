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
            pageIndicator.opacity(ui.typePopupOpenDelayed ? 0 : 1)
        }
        .background { pickerWarmUp }
        .offset(y: 1.5)

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
                .padding(.bottom, 8)
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
            Group {
                if isWhenLabel {
                    inviteTypeText(.when)
                } else {
                    Text(optionTitle)
                        .font(.body(13, .regular))
                        .foregroundStyle(Color(red: 0.70, green: 0.70, blue: 0.75))
                }
            }
            .contentTransition(.numericText())
            .id(rowTitleTransitionID)
            .transition(.blurReplace)
        }
        .animation(.snappy(duration: 0.32, extraBounce: 0), value: rowTitleTransitionID)
        .animation(.snappy, value: scrolledPageID)
    }

    private var isWhenLabel: Bool { scrolledPageID == nil || scrolledPageID == 0 }

    private var rowTitleTransitionID: String { isWhenLabel ? "when" : "option" }

    private var optionTitle: String { "Option \((scrolledPageID ?? 0) + 1)" }
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
                .offset(y: -0.5)//Fine tune so in line
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
            Text(FormatEvent.dayAndTime(times[activeIndex], wide: true, withHour: true, monthWide: false))
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
        .modifier(PagedScrollStyle(
            scrolledPageID: $scrolledPageID,
            pageWidth: $pageWidth,
            scrollProgress: $scrollProgress,
            pageCount: times.count
        ))
    }

    private func page(_ time: Date, isActive: Bool) -> some View {
        Text(FormatEvent.dayAndTime(time, wide: true, withHour: true, monthWide: false))
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


//Put into a struct as InviteTypeRow also needs this
struct PagedScrollStyle: ViewModifier {
    @Binding var scrolledPageID: Int?
    @Binding var pageWidth: CGFloat
    @Binding var scrollProgress: Double
    let pageCount: Int

    //scrollProgress is the fractional page index; it lands on a whole number when settled.
    private var isScrolling: Bool {
        abs(scrollProgress - scrollProgress.rounded()) > 0.01
    }

    func body(content: Content) -> some View {
        content
            .scrollPosition(id: $scrolledPageID)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { pageWidth = $0 }
            .trackScrollProgress(scrollProgress: $scrollProgress)
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .customHorizontalScrollFade(width: isScrolling ? 40 : 0, showFade: true)
            .customHorizontalScrollFade(width: 12, showFade: true, fromLeading: false)
            .scrollDisabled(pageCount <= 1)
            .animation(.spring(), value: isScrolling)
    }
}

