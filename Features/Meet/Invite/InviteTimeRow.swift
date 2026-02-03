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
    var hour: String? {
         times.first?.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
    }
    
    var body: some View {
        switch min(times.count, 2) {
        case 0: selectTimeView
        case 1: oneTimeView
        case 2: twoTimesView
        default: selectTimeView
        }
    }
}

extension InviteTimeRow {
    
    private var selectTimeView: some View {
        HStack {
            Text("Select Time")
                .font(.body(18, .bold))
            Spacer()
            DropDownButton(isExpanded: $vm.showTimePopup)
        }
    }
    
    @ViewBuilder private var oneTimeView: some View {
        HStack {
            Text(formatTime(date: times.first))
                .font(.body(18, .bold))
            Spacer()
            DropDownButton(isExpanded: $vm.showTimePopup)
        }
    }
    
    @ViewBuilder private var twoTimesView: some View {
            let first = times[0]
            let second = times[1]
            let hourText = hour ?? ""
        
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(formatTime(date: first, withHour: false, wideWeek: false)) or \(formatTime(date: second, withHour: false, wideWeek: false)) ")
                    .font(.body(16, .medium))
                Text(hourText)
                    .font(.body(18, .bold))
            }
            Spacer()
            DropDownButton(isExpanded: $vm.showTimePopup)
        }
    }
}


//
//#Preview {
//    InviteTimeRow()
//}


/*
 
 
 /*
  
  @ViewBuilder private var threeTimesView: some View {
      let first = times[0]
      let second = times[1]
      let third = times[2]

      let hourText = hour ?? ""
      HStack {
          (
              Text("\(formatTime(date: first, withHour: false)) | \(formatTime(date: second, withHour: false)) | \(formatTime(date: third, withHour: false)) ")
                  .font(.body(14, .regular))
                  .foregroundStyle(Color(red: 0.16, green: 0.16, blue: 0.16))
              +
              Text(hourText)
                  .font(.body(16, .bold))
          )
          Spacer()
          DropDownButton(isExpanded: $vm.showTimePopup)
      }
      .lineSpacing(6)
  }
  */
 
 
 @ViewBuilder
 private func timesSelectedView(hour: String) -> some View {
     let count = times.count
     
     HStack {
         //Have three different views here
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
 */
