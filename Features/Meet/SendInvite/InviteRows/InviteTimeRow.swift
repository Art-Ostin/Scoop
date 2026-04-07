//
//  InviteTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI


struct InviteTimeRow: View {

    @Binding var showTimePopup: Bool
    @Binding var proposedTimes: ProposedTimes
    
    let type: Event.EventType
    
    var times: [Date] {
        proposedTimes.dates.map(\.date)
    }
    
    var hour: String {
        times.first?.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) ?? ""
    }
    
    var body: some View {
        DropDownView(showOptions: $showTimePopup) {
            ProposedTimesRow(dates: times, showTimePopup: $showTimePopup, isAccept: false)
                .frame(height: 50)
        } dropDown: {
            SelectTimeView(proposedTimes: $proposedTimes, type: type, showTimePopup: $showTimePopup)
                .zIndex(2)
        }
    }
}
