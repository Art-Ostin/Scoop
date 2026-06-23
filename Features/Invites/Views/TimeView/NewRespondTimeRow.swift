//
//  NewRespondTimeRow.swift
//  Scoop Test
//
//  Created by Art Ostin on 23/06/2026.
//

import SwiftUI

struct NewRespondTimeRow: View {
    
    //1. What I am reading and updating
    @Binding var originalInvite: OriginalInvite
    @Binding var newTime: NewTimeDraft
    @Binding var respondType: ResponseType

    var rowHasIcon = false

    var body: some View {
        TimeCustomMenu {
            
        } label: {
            if respondType == .original {
                originalRowLabel
            } else {
                originalRowLabel //Update later
            }
        }
    }
}

//Original Invite Row
extension NewRespondTimeRow {
    
    private var originalRowLabel: some View {
        HStack(spacing: 10) {
            if rowHasIcon {
                clockIcon
                    .frame(width: 20)
            }
            dayDropDownRow
        }
    }
    
    private var dayDropDownRow: some View {
        HStack(spacing: 12) {
            Text(formattedDay)
                .font(.body(17, .bold))

            DropDownButton(isOpen: false, isAccept: true)
        }
    }
    
    private var formattedDay: String {
        if let selectedDay = originalInvite.selectedDay {
            let day  = selectedDay.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())  // Thursday, Sep 23
            let time = selectedDay.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))  // 22:30
            return "\(day) · \(time)"
        } else {
            return "Invite Time Expired"
        }
    }
    
    var clockIcon: some View {
        Image("MiniClockIcon")
            .scaleEffect(1.1, anchor: .bottom)
            .frame(width: 20, alignment: .leading)
    }
}

//Selecting New Time Row
extension NewRespondTimeRow {
    
}
