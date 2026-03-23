//
//  InviteTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI


struct InviteTimeRow: View {

    @Bindable var vm: TimeAndPlaceViewModel
    @Bindable var ui: TimeAndPlaceUIState
    
    var times: [Date] {
        vm.event.proposedTimes.dates.map(\.date)
    }
    
    var hour: String {
        times.first?.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) ?? ""
    }
    
    var body: some View {
        
        DropDownView(showOptions: $ui.showTimePopup) {
            inviteTimeRow
        } dropDown: {
            SelectTimeView(vm: vm, showTimePopup: $ui.showTimePopup, showInvitedTimes: .constant(false))
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
                oneDayView
            } else if times.count == 2 {
                twoDaysView
            } else if times.count == 3 {
                threeDaysView
            }
            Spacer()
            DropDownButton(isExpanded: $ui.showTimePopup)
        }
        .frame(height: ui.rowHeight)
    }
    
    private var noTimeView: some View {
        Text("Select Time")
            .font(.body(18, .bold))
    }
    
    private var oneDayView: some View {
        Text(formatTime(date: times.first))
            .font(.body(18, .bold))
    }
    
    private var twoDaysView: some View {
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
            Text(hour)
                .font(.body(16, .regular))
                .kerning(0.7)
        }
    }
    
    private var threeDaysView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                ForEach(times, id: \.self) { time in
                    
                    let text = formatTime(date: time, withHour: false, wideWeek: false) + (time != times.last ? ", " : "")
                    
                    Text(text)
                        .font(.body(15, .bold))
                }
            }
            Text(hour)
                .font(.body(16, .regular))
                .kerning(0.7)
        }
    }
}



