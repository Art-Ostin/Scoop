//
//  TimePopupContainer.swift
//  Scoop
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

enum TimePopupPage: Hashable { case invitedTimes, newTime}

struct TimePopupContainer: View {

    @State private var invitedTimesHeight: CGFloat = 0
    @State private var selectTimeHeight: CGFloat = 0
    
    //Injected -- three values can change (1) The response Type (2) The selected Day (3) Modified Invite proposed Times (4) Which pop
    @Binding var respondType: ResponseType
    @Binding var selectedDay: Date?
    @Binding var newProposedTimes: ProposedTimes
    @Binding var page: TimePopupPage?

    //ProposedTimes open here.
    let times: ProposedTimes

    var body: some View {
        VStack(spacing: page == .invitedTimes ? Spacing.md : Spacing.sm) {
            popupTitleAndButton
            pagerSection
        }
        .padding(.top, page == .invitedTimes ? 20 : Spacing.md)
        .padding(.bottom, page == .invitedTimes ? 20 :  -Spacing.xs)
        .frame(maxWidth: page == .invitedTimes ? 310 : 325) //Width matches that in SelectTimeView
        .animation(.spring(duration: 0.3), value: page)
    }
}

extension TimePopupContainer {
    
    private var popupTitleAndButton: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(page == .newTime ? "Suggest New Time" : "Invited Times")
                    .font(.body(17, .medium))
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
        .padding(.horizontal, Spacing.margin)
    }
    
    private var subTitle: some View {
        HStack(spacing: 6) {
            Text("Propose up to 3 days")
                .font(.body(11, .regular))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private var pagerSection: some View {
        //Top aligned: the two pages differ in height, and the frame below clips to
        //the active one — centred, the shorter page sits below the visible window
        HorizontalScrollView(progress: .constant(0), alignment: .top) {
            InvitedTimes(proposedTimes: times, selectedDay: $selectedDay, respondType: $respondType)
                .padding(.horizontal, Spacing.margin)
                .containerRelativeFrame(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                .getHeight($invitedTimesHeight)
                .id(TimePopupPage.invitedTimes)
            
            SelectTimeView(proposedTimes: $newProposedTimes, isRespondMode: true)
                .padding(.horizontal, Spacing.margin)
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
