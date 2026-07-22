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
    
    @State var page: TimePopupPage? = .invitedTimes
    
    var body: some View {
        VStack {
            popupTitleAndButton
            pagerSection
        }
        .contentMargins(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: 320)
        .background(Color.appCanvas, in: .rect(cornerRadius: 36))
        .animation(.spring(duration: 0.2), value: page)
    }
}

extension TimePopupContainer {
    
    private var popupTitleAndButton: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(page == .invitedTimes ? "Invited Times" : "Choose New Time")
                    .font(.body(17, .medium))
                    .foregroundStyle(Color.textPrimary)
                    .transition(.blurReplace)
                
                if page == .newTime {
                    Text("Propose 1-3 days to meet")
                        .font(.body(11, .regular))
                        .foregroundStyle(Color.textTertiary)
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
    }
    
    
    private var pagerSection: some View {
        PagerScrollView {
            InvitedTimes(proposedTimes: times, selectedDay: $selectedDay, respondType: $respondType)
                .containerRelativeFrame(.horizontal)
                .id(TimePopupPage.invitedTimes)
            
            RespondNewTime()
                .containerRelativeFrame(.horizontal)
                .id(TimePopupPage.newTime)
        }
        .scrollPosition(id: $page)
        .scrollDisabled(true)
    }
}
