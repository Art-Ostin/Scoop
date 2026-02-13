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
        times.first?.formatted(
            .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
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
                    (
                        Text(formatTime(date: times.first, withHour: false, wideWeek: false))
                            .font(.body(17, .bold))
                            .foregroundStyle(.black)
                        +
                        Text(" or ")
                            .font(.body(16, .medium))
                            .foregroundStyle(Color.grayText)
                        +
                        Text(formatTime(date: times.last, withHour: false, wideWeek: false))
                            .font(.body(17, .bold))
                            .foregroundStyle(.black)
                    )
                    Text(hourText)
                        .font(.body(16, .regular))
                        .kerning(0.7)
                }
            }
            Spacer()
            DropDownButton(isExpanded: $vm.showTimePopup)
        }
        .onAppear {
            print(hour)
        }
    }
}



