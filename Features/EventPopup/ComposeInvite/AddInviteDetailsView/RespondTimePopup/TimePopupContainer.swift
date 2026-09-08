//
//  TimePopupContainer.swift
//  Scoop
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

enum TimePopupPage: Hashable { case invitedTimes, newTime}

struct TimePopupContainer: View {

    private static let invitedInset = Spacing.md

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
        .padding(.bottom, page == .invitedTimes ? Spacing.md : 0)
        .frame(width: pageWidth)
        .animation(.expand, value: page) //the platter's width, the pager's height reflow and the title crossfade
    }
}

extension TimePopupContainer {
    
    private var popupTitleAndButton: some View {
        HStack(alignment: page == .newTime ? .top : .center) {
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

    private var invitedAir: CGFloat {
        times.dates.count == ProposedTimes.maxCount ? 6 : 0
    }

    private var invitedColumnInset: CGFloat { Self.invitedInset + invitedAir }

    private var columnInset: CGFloat {
        page == .newTime ? SelectTimeView.columnInset : invitedColumnInset
    }

    private var pageWidth: CGFloat {
        page == .invitedTimes ? Self.invitedWidth + 2 * invitedAir : SelectTimeView.platterWidth
    }

    private var subTitle: some View {
        Text("Propose up to 3 days")
            .font(.body(13, .regular)) //Matches compose's subtitle (SelectTimeView.titleSection); the two rows are separate copies of one design
            .foregroundStyle(Color.textSecondary)
    }

    private var pagerSection: some View {
        HorizontalScrollView(progress: .constant(0), alignment: .top) {
            InvitedTimes(proposedTimes: times, selectedDay: $selectedDay, respondType: $respondType)
                .padding(.horizontal, invitedColumnInset)
                .containerRelativeFrame(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                .getHeight($invitedTimesHeight)
                .id(TimePopupPage.invitedTimes)
            
            SelectTimeView(proposedTimes: $newProposedTimes, isRespondMode: true)
                .padding(.horizontal, SelectTimeView.columnInset)
                .containerRelativeFrame(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                .clipped()
                .getHeight($selectTimeHeight)
                .id(TimePopupPage.newTime)
        }
        .frame(height: activePageHeight, alignment: .top)
        .clipped()
        .scrollPosition(id: $page)
        .scrollDisabled(true)
    }

    private var activePageHeight: CGFloat? {
        let height = page == .invitedTimes ? invitedTimesHeight : selectTimeHeight
        return height > 0 ? height : nil
    }
}
