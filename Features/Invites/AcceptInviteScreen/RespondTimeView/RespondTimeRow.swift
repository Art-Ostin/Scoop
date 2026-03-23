//
//  RespondTimeView.swift
//  Scoop
//
//  Created by Art Ostin on 22/03/2026.
//

import SwiftUI

struct RespondTimeView: View {
    
    @Bindable var vm: TimeAndPlaceViewModel
    
    @Bindable var ui: ProfileUIState
    @Binding var selectedDate: Date?
    
    let event: UserEvent
        
    var body: some View {
        DropDownView(verticalOffset: 58, showOptions: $ui.showTimePopup) {
            timeRow
        } dropDown: {
            RespondTimeContainer(vm: vm, selectedDay: $selectedDate, showTime: $ui.showTimePopup, dates: event.proposedTimes.availableDates())
        }
    }
}

extension RespondTimeView {
    
    
    private var timeRow: some View {
        HStack(spacing: 24) {
            Image("MiniClockIcon")
                .scaleEffect(1.3)
                .opacity(ui.showTimePopup ? 0.3 : 1)
            
            if let date = event.proposedTimes.firstAvailableDate {
                if let message = event.message {
                    availableDateWithMessage(message: message, date: date)
                } else {
                    availableDateNoMessage(date: date)
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private func availableDateWithMessage(message: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(EventFormatting.fullDateAndTime(date))
                    .font(.body(16, .medium))
                Spacer()
                DropDownButton(isExpanded: $ui.showTimePopup, isAccept: true)
            }
            Text(message)
                .font(.footnote)
                .foregroundStyle(.gray)
                .opacity(ui.showTimePopup ? 0.3 : 1)
        }
    }
    
    private func availableDateNoMessage(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(EventFormatting.fullDate(date, wideMonth: true))
                .font(.body(16, .medium))
            Text(EventFormatting.hourTime(date))
                .font(.footnote)
                .foregroundStyle(.gray)
        }
    }
}
