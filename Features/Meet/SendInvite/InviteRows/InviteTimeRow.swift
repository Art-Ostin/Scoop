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
            inviteTimeRow
        } dropDown: {
            SelectTimeView(proposedTimes: $proposedTimes, type: type, showTimePopup: $showTimePopup)
                .zIndex(2)
        }
    }
}

extension InviteTimeRow {
    
    private var inviteTimeRow: some View {
        HStack {
            if times.isEmpty {
                noTimeView
            } else if times.count == 1 {
                EmptyView() //Update here 
            } else if times.count == 2 {
                EmptyView() //Update here
            } else if times.count == 3 {
                EmptyView() //Update here
            }
            Spacer()
            DropDownButton(isExpanded: $showTimePopup)
        }
        .frame(height: 50)
    }
    
    private var noTimeView: some View {
        Text("Select Time")
            .font(.body(18, .bold))
    }
}
