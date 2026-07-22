//
//  TimePopupContainer.swift
//  Scoop Test
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
        VStack(spacing: 0) {
            popupTitleAndButton
            pagerSection
        }
        .padding(.top, page == .invitedTimes ? 20 : 16)
        .padding(.bottom, page == .invitedTimes ? 20 :  -Spacing.xs)
        .frame(maxWidth: page == .invitedTimes ? 310 : 325)
        .background(Color.white, in: .rect(cornerRadius: CornerRadius.customMenu))
        .animation(.spring(duration: 0.3), value: page)
    }
}

extension TimePopupContainer {
    
    private var popupTitleAndButton: some View {
        HStack(alignment: .top) {
            ZStack(alignment: .leading) {
                Text(page == .newTime ? "Choose New Time" : "Invited Times")
                    .font(.body(17, .medium))
                    .foregroundStyle(Color.textPrimary)
                    .id(page == .newTime)
                    .transition(.blurReplace)
            }
            .overlay(alignment: .bottomLeading) {
                if page == .newTime { //Overlay so doesn't push invitedTimes view down during transition
                    Text("Propose 1-3 days to meet")
                        .font(.body(11, .regular))
                        .foregroundStyle(Color.textTertiary)
                        .offset(y: 12)
                }
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
        .padding(.bottom, 16)
    }
    
    

    private var pagerSection: some View {
        PagerScrollView(verticalAlignment: .top) {
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
