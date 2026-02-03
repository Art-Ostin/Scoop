//
//  InviteTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI


struct InviteTimeRow: View {

    @Bindable var vm: TimeAndPlaceViewModel

    var times: [Date] {
        vm.event.proposedTimes.dates
    }
    
    var body: some View {
        let hour = times.first?.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
        
        if times.isEmpty {
            selectTimeView
        } else {
            if let hour {
                timesSelectedView(hour: hour)
            }
        }
    }
}
extension InviteTimeRow {
    
    private var selectTimeView: some View {
        HStack {
            Text("Select Time")
                .font(.body(18, .regular))   // use your custom extension
            Spacer()
            DropDownButton(isExpanded: $vm.showTimePopup)
        }
    }
    
    @ViewBuilder
    private func timesSelectedView(hour: String) -> some View {
        let count = times.count
        
        HStack {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(times, id: \.self) { time in
                        Text(formatTime(date: time, withHour: false))
                            .font(.body(count == 1 ? 18 : (count == 2 ? 16 : 14) , .bold))
                    }
                }
                Text(hour)
                    .font(.body(18, .bold))
            }
            .offset(y: count == 3 ? -4 : 0)
            
            Spacer()
            DropDownButton(isExpanded: $vm.showTimePopup)
        }
    }
}



//
//#Preview {
//    InviteTimeRow()
//}

