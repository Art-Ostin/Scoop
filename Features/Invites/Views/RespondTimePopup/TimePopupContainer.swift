//
//  TimePopupContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

enum TimePopupPage: Hashable { case invitedTimes, newTime}

struct TimePopupContainer: View {
    
    //Injected -- three values can change (1) The response Type (2) The selected Day (3) Modified Invite proposed Times
    @Binding var respondType: ResponseType
    @Binding var selectedDay: Date?
    @Binding var newProposedTimes: ProposedTimes
    
    //ProposedTimes open here.
    let times: ProposedTimes
    
    @Binding var page: TimePopupPage?
    
    var body: some View {
        VStack(spacing: 0) {
            popupTitleAndButton
            pagerSection
        }
        .padding(.vertical, 20)
        .frame(maxWidth: 320)
        .background(Color.appCanvas.opacity(0.5), in: .rect(cornerRadius: CornerRadius.customMenu))
        .animation(.spring(duration: 0.2), value: page)
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
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    

    private var pagerSection: some View {
        PagerScrollView {
            InvitedTimes(proposedTimes: times, selectedDay: $selectedDay, respondType: $respondType)
                .padding(.horizontal, 24)
                .containerRelativeFrame(.horizontal)
                .id(TimePopupPage.invitedTimes)
            
            RespondNewTime()
                .padding(.horizontal, 24)
                .containerRelativeFrame(.horizontal)
                .id(TimePopupPage.newTime)
        }
        .scrollPosition(id: $page)
        .scrollDisabled(true)
    }
}
