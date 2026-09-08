//
//  TimePopupContainer.swift
//  Scoop
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

enum TimePopupPage: Hashable { case invitedTimes, newTime}

struct TimePopupContainer: View {

    //Geometry: the invited-times column. The propose page borrows SelectTimeView.columnInset because that
    //is what centres the day grid in the platter; this page has no grid to centre, so its cells run closer
    //to the platter edge instead of inheriting a number that was never about them.
    private static let invitedInset = Spacing.md

    //Geometry: the invited-times platter, and the size the menu seeds its first bloom with — every open
    //lands on this page. Only the propose page has an incompressible width (SelectTimeView.platterWidth
    //centres a 298pt day grid), so it is the one page that earns 346. This page answers to its own header:
    //"Invited Times" + "Can't make it?" + 2 × invitedInset needs 246, so this sits 70pt clear of its floor
    //and still leaves a 30pt step out to the propose page.
    static let invitedWidth: CGFloat = 316

    //Injected -- three values can change (1) The response Type (2) The selected Day (3) Modified Invite proposed Times (4) Which pop
    @Binding var respondType: ResponseType
    @Binding var selectedDay: Date?
    @Binding var newProposedTimes: ProposedTimes
    @Binding var page: TimePopupPage?

    //ProposedTimes open here.
    let times: ProposedTimes

    //Local view state
    @State private var invitedTimesHeight: CGFloat = 0
    @State private var selectTimeHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: page == .invitedTimes ? Spacing.md : Spacing.sm) {
            popupTitleAndButton
            pagerSection
        }
        .padding(.top, Spacing.lg) //the platter's top air, as in propose mode
        .padding(.bottom, page == .invitedTimes ? Spacing.md : 0) //New-time page: the wheel runs to the platter edge and dissolves there (see TimePicker)
        //A definite pin, and the OUTERMOST width modifier: both pager pages size off it through their
        //containerRelativeFrame, and the menu's hidden sizer measures this view's own width to place the
        //platter. Wrapping it in a flexible frame decouples the two — the sizer stops tracking the page
        //flip and the platter keeps the other page's width while the content overflows its mask.
        .frame(width: pageWidth)
        .animation(.expand, value: page) //the platter's width, the pager's height reflow and the title crossfade
    }
}

extension TimePopupContainer {
    
    private var popupTitleAndButton: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(page == .newTime ? "Suggest New Time" : "Invited Times")
                    .font(.body(18, .medium))
                    .foregroundStyle(Color.textPrimary)
                    .id(page == .newTime)
                    .transition(.blurReplace)
                if page == .newTime {subTitle}
            }
            Spacer()
            ToggleResponseMode(
                responseType: $respondType,
                timePopupPage: $page,
                anyNewProposedTimes: newProposedTimes.dates.count > 0,
                anyAvailableInvitedDays: times.availableDates().count > 0
            )
        }
        .padding(.horizontal, columnInset) //Shared across the swap, so it rides each page's own column
    }

    //The propose page's inset centres its day grid; the invited-times page answers only to its cells
    private var columnInset: CGFloat {
        page == .newTime ? SelectTimeView.columnInset : Self.invitedInset
    }

    //Tested against `.invitedTimes`, not `.newTime`, because `page` IS the pager's `.scrollPosition(id:)`
    //binding and is reported nil mid-swap: nil must widen, never narrow, or the platter dips inward for a
    //frame in the middle of expanding. Every open lands on `.invitedTimes` (see the menu's `onOpen`), so
    //the narrow width is still what the platter blooms into.
    private var pageWidth: CGFloat {
        page == .invitedTimes ? Self.invitedWidth : SelectTimeView.platterWidth
    }

    private var subTitle: some View {
        Text("Propose up to 3 days")
            .font(.body(14, .regular))
            .foregroundStyle(Color.textSecondary)
    }

    private var pagerSection: some View {
        HorizontalScrollView(progress: .constant(0), alignment: .top) {
            InvitedTimes(proposedTimes: times, selectedDay: $selectedDay, respondType: $respondType)
                .padding(.horizontal, Self.invitedInset)
                .containerRelativeFrame(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                .getHeight($invitedTimesHeight)
                .id(TimePopupPage.invitedTimes)
            
            SelectTimeView(proposedTimes: $newProposedTimes, isRespondMode: true)
                .padding(.horizontal, SelectTimeView.columnInset)
                .containerRelativeFrame(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                //Both pages take the pager's width, so while the invited page is active this one is 280 and
                //its 346pt day grid outgrows it by 33pt a side. The LEFT half of that spill lands inside the
                //visible page — the grid's first column starts 9pt before this page's origin — and showed as a
                //sliced weekday letter and day number against the platter's trailing edge. Nothing to cut when
                //the page is active: at 346 the grid fits its column inset exactly.
                .clipped()
                .getHeight($selectTimeHeight)
                .id(TimePopupPage.newTime)
        }
        .frame(height: activePageHeight, alignment: .top)
        .clipped()
        .scrollPosition(id: $page)
        .scrollDisabled(true)
    }

    //Each page hugs its own content. Sharing the taller one sized every invited list for the propose
    //page's grid-and-wheel, so a one- or two-option invite carried ~100pt of dead air under its last cell.
    //The menu places this platter `.above` as `aboveBottom - height + placementOffsetY`, so its BOTTOM is
    //pinned to the row and a shorter page shrinks upward rather than jumping.
    //Tested against `.invitedTimes` for the same reason as `pageWidth`: `page` is the pager's
    //`.scrollPosition(id:)` binding and is reported nil mid-swap, so nil must take the TALLER page or the
    //platter dips for a frame in the middle of growing.
    private var activePageHeight: CGFloat? {
        let height = page == .invitedTimes ? invitedTimesHeight : selectTimeHeight
        return height > 0 ? height : nil
    }
}
