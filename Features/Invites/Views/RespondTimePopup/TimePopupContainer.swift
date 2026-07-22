//
//  TimePopupContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct TimePopupContainer: View {
    
    //Injected -- three values can change (1) The response Type (2) The selected Day (3) Modified Invite proposed Times
    @Binding var respondType: ResponseType
    @Binding var selectedDay: Date?
    @Binding var newProposedTimes: ProposedTimes
    
    //ProposedTimes open here.
    let times: ProposedTimes
    
    
    @State var showNewTime = false
    
    var body: some View {
        VStack {
            popupTitleAndButton
            
            
        }
        .background(Color.appCanvas, in: .rect(cornerRadius: 36))
        .animation(.snappy, value: showNewTime)
    }
}


extension TimePopupContainer {
    
    private var popupTitleAndButton: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(showNewTime ? "Invited Times" : "Choose New Time")
                    .font(.body(17, .medium))
                    .foregroundStyle(Color.textPrimary)
                    .transition(.blurReplace)
                
                if showNewTime {
                    Text("Propose 1-3 days to meet")
                        .font(.body(11, .regular))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            ToggleResponseMode(
                responseType: $respondType,
                showNewTime: $showNewTime,
                anyNewProposedTimes: newProposedTimes.dates.count > 0,
                anyAvailableInvitedDays: times.availableDates().count > 0
            )
        }
    }
    
    
    private var pagerSection: some View {
        
    }
}
