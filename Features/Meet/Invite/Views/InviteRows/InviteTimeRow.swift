//
//  InviteTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

//Consistent Row heights so 'option' and actual text line up. Not done HStack for each row
//as need the right side of the rows to be one single button
enum RowH {static let smallHour: CGFloat = 13 ; static let singleTime: CGFloat = 17; static let multipleTime: CGFloat = 15 ; static let noTimeHeight: CGFloat = 16}

struct InviteTimeRow: View {

    @Bindable var ui: TimeAndPlaceUIState
    @Binding var showTimePopup: Bool
    @Binding var proposedTimes: ProposedTimes

    //Live edits happen on this draft inside the open menu; the real binding (and
    //therefore this row's label) is only updated when the menu is dismissed.
    @State private var draft = ProposedTimes()

    //Measured viewport width of the horizontal pager. Each time page is pinned to
    //exactly this so .paging advances one full time per swipe (no partial reveal).
    @State private var pageWidth: CGFloat = 0

    var times: [Date] {
        proposedTimes.dates.map(\.date)
    }
    
    var hour: String {
        times.first?.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) ?? ""
    }
    
    @State private var scrollProgress: Double = 0

    //The pager's current page id (== its index). Two-way with the scrollView so we
    //can also snap it programmatically (instantly) on dismiss.
    @State private var scrolledPageID: Int?

    //Global frame of the *active* page's text. Handed to the menu as its morph
    //anchor so the open/close lens zooms around whatever time is on screen, pinned
    //to that text (ignoring the row padding and the chevron), never the whole pager.
    @State private var activeTimeFrame: CGRect = .zero

    //The page the lens zooms around: the scrolled page, clamped into range.
    private var activeIndex: Int {
        guard !times.isEmpty else { return 0 }
        return min(max(scrolledPageID ?? 0, 0), times.count - 1)
    }


    var body: some View {
        HStack {
            inviteTypeText(.when)
            Spacer()
            timeCustomMenu
            .overlay(alignment: .bottom) {
                if times.count > 1 {
                    AnimatedPageIndicator(
                        count: times.count,
                        progress: scrollProgress)
                    .scaleEffect(0.6, anchor: .bottom)
                    .padding(.bottom, 8)
                }
            }
        }
        .transition(.opacity.animation(.smooth(duration: 0.2)))
    }
}

//If less than 2 proposed times
extension InviteTimeRow {
    
    
    
    private var timeCustomMenu: some View {
            TimeCustomMenu(
                // Zoom the open/close lens around the *active* page's text, pinned to
                // its bounds. nil (no times yet) falls back to the whole label.
                morphAnchor: activeTimeFrame == .zero ? nil : activeTimeFrame,
                onOpen: {
                    draft = proposedTimes        // seed the draft from the committed value
                    ui.timePopupOpen = true
                },
                onClose: {
                    proposedTimes = draft         // commit once, the moment it dismisses
                    ui.timePopupOpen = false
                    // Snap the pager (instantly, no animation) to the page we zoomed
                    // in on — or the last one if it no longer exists — so the row
                    // reappears under the lens at the right place, not pinned left.
                    let count = draft.dates.count
                    if count > 0 {
                        let target = min(max(scrolledPageID ?? 0, 0), count - 1)
                        var tx = Transaction(); tx.disablesAnimations = true
                        withTransaction(tx) { scrolledPageID = target }
                    }
                }
            ) {
                SelectTimeView(proposedTimes: $draft)
                    .zIndex(2)
            } label: {
                TimeRowMenuLabel(
                    times: times,
                    activeIndex: activeIndex,
                    pageWidth: $pageWidth,
                    scrollProgress: $scrollProgress,
                    scrolledPageID: $scrolledPageID,
                    activeTimeFrame: $activeTimeFrame
                )
            }
            .environment(\.isLiveTimeRow, true)
        }
}

//The menu's trigger/label. In the row (isLive) it's the full interactive pager;
//inside the menu's morph overlay (not isLive) it collapses to just the active
//time's text — so the dismiss lens only ever shows/zooms around that one time.
private struct TimeRowMenuLabel: View {

    let times: [Date]
    let activeIndex: Int
    @Binding var pageWidth: CGFloat
    @Binding var scrollProgress: Double
    @Binding var scrolledPageID: Int?
    @Binding var activeTimeFrame: CGRect

    @Environment(\.isLiveTimeRow) private var isLive

    var body: some View {
        if isLive {
            liveLabel
        } else {
            collapsedLabel
        }
    }

    //Full row content: the horizontal pager (or "Choose Time") + the chevron.
    private var liveLabel: some View {
        HStack(spacing: times.count == 0 ? 12 : 0) {
            if times.count == 0 {
                chooseTimeText
                    .padding(.vertical, 30)
            } else {
                TimeRowScrollLabel(
                    times: times,
                    activeIndex: activeIndex,
                    pageWidth: $pageWidth,
                    scrollProgress: $scrollProgress,
                    scrolledPageID: $scrolledPageID,
                    activeTimeFrame: $activeTimeFrame
                )
            }
            DropDownButton(isOpen: false)
        }
    }

    //What the morph lens shrinks to / blooms from: only the active time, matched to
    //the pager's text style, with no padding/chevron so the glass pins to the text.
    @ViewBuilder
    private var collapsedLabel: some View {
        if times.indices.contains(activeIndex) {
            Text(FormatEvent.dayAndTime(times[activeIndex], wide: true, withHour: true))
                .font(.body(17, .medium))
        } else {
            chooseTimeText
        }
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

    @Environment(\.isLiveTimeRow) private var isLive

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(times.enumerated()), id: \.offset) { idx, time in
                    Text(FormatEvent.dayAndTime(time, wide: true, withHour: true))
                        .font(.body(17, .medium))
                        //Measure the *active* page's tight text bounds (before the
                        //page-width frame) — this is the menu's morph anchor.
                        .background { activeTimeProbe(idx) }
                        .frame(width: pageWidth, alignment: .trailing)
                }
            }
            .offset(x: -12)//So in line with the rest of the content
            .padding(.vertical, 30)
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrolledPageID)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { newWidth in
            guard isLive else { return }
            pageWidth = newWidth
        }
        .trackScrollProgress(scrollProgress: $scrollProgress)
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        //Fade only when scrolling for leading as then it doesn't hide the time row, when stationary.
        .customHorizontalScrollFade(width: scrollProgress == 0 ? 0 : 40, showFade: true, fromLeading: true, isCardInvite: false)
        .customHorizontalScrollFade(width: 12, showFade: true, fromLeading: false, isCardInvite: false)
        .scrollDisabled(times.count <= 1)
    }

    @ViewBuilder
    private func activeTimeProbe(_ idx: Int) -> some View {
        if idx == activeIndex {
            Color.clear
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                    guard isLive else { return }
                    activeTimeFrame = frame
                }
        }
    }
}

extension EnvironmentValues {
    /// True only for the row's own rendering of the time-pager label. The menu's
    /// iOS 26 morph re-renders the same label in a separate window without it, so
    /// that copy stays read-only and can't clobber the row's pageWidth/scroll state.
    @Entry var isLiveTimeRow: Bool = false
}



/* Old
 
 
 @ViewBuilder
 private var leadingText: some View {
     if times.count <= 1 {
         singleTimeLeadingText
     } else {
         multipleTimeLeadingText
     }
 }
 
 private var singleTimeLeadingText: some View {
     inviteTypeText(.when)
         .frame(height: times.count == 0 ? RowH.noTimeHeight : RowH.singleTime)
 }
 

 private var multipleTimeLeadingText: some View {
     VStack(alignment: .leading, spacing: 8) {
         Text("When")
             .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
             .font(.body(12, .bold))
             .frame(height: RowH.smallHour)
         
         
         ForEach(0..<times.count, id: \.self) { idx in
             Text("Option \(idx + 1)")
                 .kerning(0.24)
                 .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                 .font(.body(12, .regular))
                 .frame(height: RowH.multipleTime)
         }
     }
 }

 private func mutlipleTimeTrailingDay(_ idx: Int) ->  some View {
     let day = times[idx]
     
     return Text(FormatEvent.dayAndTime(day, withHour: false))
         .font(.body(15, .regular))
         .opacity(ui.typePopupOpenDelayed ? 0 : 1)
         .frame(height: RowH.singleTime)
 }
 
 @ViewBuilder
 private var multipleTimeTrailingHour: some View {
     if let firstDay = times.first {
         Text(FormatEvent.hourTime(firstDay))
             .font(.body(13, .bold))
             .opacity(ui.typePopupOpenDelayed ? 0 : 1) //Hide it when typePopup Open -> Makes bit smoother
             .frame(height: RowH.smallHour)
     }
 }

 
 private var multipleTimeTrailingText: some View {
     VStack(alignment: .trailing, spacing: 8){
         multipleTimeTrailingHour
         
         ForEach(times.indices, id: \.self) {idx in
             mutlipleTimeTrailingDay(idx)
         }
     }
 }
 @ViewBuilder
 private var singleTimeTrailingText: some View {
     if times.count == 0 {
         Text("Choose Time")
             .kerning(0.32)
             .font(.body(16, .regular))
             .foregroundStyle(Color(white: 0.4))
             .transition(.opacity.animation(.smooth(duration: 0.2)))
             .frame(height: RowH.noTimeHeight)
     } else if let proposedDay = times.first {
         Text( FormatEvent.dayAndTime(proposedDay, wide: true, withHour: true))
             .font(.body(17, .medium))
             .transition(.opacity.animation(.smooth(duration: 0.2)))
             .frame(height: RowH.singleTime)
     }
 }
 private var trailingText: some View {
     HStack(spacing: 12) {
         if times.count <= 1 {
             singleTimeTrailingText
         } else {
             multipleTimeTrailingText
         }
         DropDownButton(isOpen: showTimePopup)
     }
 }
 
 private var trailingTextAsMenuLabel: some View {
     TimeCustomMenu(
         onOpen: {
             draft = proposedTimes        // seed the draft from the committed value
             ui.timePopupOpen = true
         },
         onClose: {
             proposedTimes = draft         // commit once, the moment it dismisses
             ui.timePopupOpen = false
         }
     ) {
         SelectTimeView(proposedTimes: $draft)
             .zIndex(2)
     } label: {
         trailingText
     }
 }



 */
