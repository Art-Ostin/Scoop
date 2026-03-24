//
//  RespondTimeView.swift
//  Scoop
//
//  Created by Art Ostin on 22/03/2026.
//

import SwiftUI

struct RespondTimeRow: View {
    //Using vm as multiple respond models
    @Bindable var vm: RespondViewModel
    @Binding var showTimePopup: Bool
    
    var body: some View {
        DropDownView(verticalOffset: 58, showOptions: $showTimePopup) {
            timeRow
        } dropDown: {
            RespondSelectTime(vm: vm, showTimePopup: $showTimePopup)
        }
    }
}

extension RespondTimeRow {
    
    private var timeRow: some View {
        HStack(spacing: 24) {
            Image("MiniClockIcon")
                .scaleEffect(1.3)
                .opacity(showTimePopup ? 0.3 : 1)
            
            if vm.respondDraft.respondType == .original {
                if let date = vm.respondDraft.selectedDate {
                    if let message = vm.respondDraft.event.message {
                        availableDateWithMessage(message: message, date: date)
                    } else {
                        availableDateNoMessage(date: date)
                    }
                }
            } else {
                inviteTimeRow
            }
        }
    }
    
    private func availableDateWithMessage(message: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(FormatEvent.dayAndTime(date))
                    .font(.body(16, .medium))
                Spacer()
                DropDownButton(isExpanded: $showTimePopup, isAccept: true)
            }
            Text(message)
                .font(.footnote)
                .foregroundStyle(.gray)
                .opacity(showTimePopup ? 0.3 : 1)
                .lineLimit(4)
        }
    }
    
    private func availableDateNoMessage(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(FormatEvent.dayAndTime(date))
                .font(.body(16, .medium))
            Text(FormatEvent.hourTime(date))
                .font(.footnote)
                .foregroundStyle(.gray)
        }
    }
    
    @ViewBuilder
    private var inviteTimeRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            let dates = vm.respondDraft.newTime.proposedTimes.dates.map(\.date)
            HStack(spacing: 2) {
                if dates.count == 1 {
                    Text(formatTime(date: dates.first))
                        .font(.body(16, .medium))
                } else if dates.count == 2 {
                    twoDayView(dates)
                } else if dates.count == 3 {
                    threeDayView(dates)
                }
                Spacer(minLength: 12)
                DropDownButton(isExpanded: $showTimePopup)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            
            if let message = vm.respondDraft.event.message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .opacity(showTimePopup ? 0.3 : 1)
            }
        }
        .overlay(alignment: .topLeading) {
            if vm.respondDraft.respondType != .original {
                Text("Custom Time")
                    .kerning(0.5)
                    .foregroundStyle(Color.accent)
                    .font(.body(10, .bold))
            }
        }
    }
    
    
    private func twoDayView(_ dates: [Date]) -> some View {
        Text(formatTime(date: dates.first, withHour: false, wideWeek: false))
            .font(.body(16, .medium))
        +
        Text(" or ")
            .font(.body(15, .italic))
            .foregroundStyle(Color.grayText)
        +
        Text("\(formatTime(date: dates.last, withHour: false, wideWeek: false)) · ")
            .font(.body(16, .medium))
        +
        Text(hour)
            .font(.body(14, .regular))
            .foregroundStyle(Color.grayText)
            .kerning(0.7)
    }
    
    private func threeDayView(_ dates: [Date]) -> some View {
        HStack {
            ForEach(dates, id: \.self) { date in
                
                if dates.count == 1 {
                    
                    
                    Text(formatTime(date: dates.first))
                        .font(.body(16, .medium))
                }
                
                
                let text = formatTime(date: date, withHour: false, wideWeek: false) + (date != dates.last ? ", " : " · ")
                Text(text)
                    .font(.body(15, .medium))
            }
            Text(hour)
                .font(.body(14, .regular))
                .foregroundStyle(Color.grayText)
        }
    }
    
    private var hour: String {
        let dates = vm.respondDraft.newTime.proposedTimes.dates.map { $0.date}
        return dates.first?.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) ?? ""
    }
}
