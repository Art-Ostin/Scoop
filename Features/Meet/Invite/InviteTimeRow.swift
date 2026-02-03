//
//  InviteTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI


struct InviteTimeRow: View {

    @Bindable var vm: TimeAndPlaceViewModel
    @State var isTest: Bool = false
    @State var isTwoTest = false
    
    var times: [Date] {
        vm.event.proposedTimes.dates
    }
    var hour: String? {
         times.first?.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
    }
    
    var body: some View {
        let hourText = hour ?? ""
        HStack {
            if times.isEmpty {
                Text("Select Time")
                    .font(.body(18, .bold))
            } else if times.count == 1 {
                Text(formatTime(date: times.first))
                    .font(.body(18, .bold))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(formatTime(date: times.first, withHour: false, wideWeek: false)) or \(formatTime(date: times.last, withHour: false, wideWeek: false)) ")
                        .font(.body(16, .medium))
                    Text(hourText)
                        .font(.body(18, .bold))
                }
            }
            Spacer()
            DropDownButton(isExpanded: $vm.showTimePopup)
        }
    }
}



