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
        .frame(maxWidth: SelectTimeView.platterWidth) //One width for both pages: the platter is pinned to the screen margin, so a narrower page would slide sideways on the swap
        .animation(.expand, value: page) //the pager's height reflow and the title crossfade
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

    private var subTitle: some View {
        Text("Propose up to 3 days")
            .font(.body(14, .regular))
            .foregroundStyle(Color.textSecondary)
    }

    private var pagerSection: some View {
        //Top aligned: the two pages differ in height, and the frame below clips to
        //the active one — centred, the shorter page sits below the visible window
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
                .getHeight($selectTimeHeight)
                .id(TimePopupPage.newTime)
        }
        .frame(height: activePageHeight, alignment: .top)
        .clipped()
        .scrollPosition(id: $page)
        .scrollDisabled(true)
    }

    private var activePageHeight: CGFloat? {
        let height = page == .newTime ? selectTimeHeight : invitedTimesHeight
        return height > 0 ? height : nil
    }
}
