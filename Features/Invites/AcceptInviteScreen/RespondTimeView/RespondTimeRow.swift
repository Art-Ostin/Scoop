//
//  RespondTimeView.swift
//  Scoop
//
//  Created by Art Ostin on 22/03/2026.
//




import SwiftUI

struct RespondTimeView: View {
    
    @Bindable var ui: ProfileUIState
    @Binding var selectedDate: Date?
    
    let event: UserEvent
    
    @State private var topLineBottom: CGFloat = 0
    
    private let rowHeight: CGFloat = 60
    private let dropdownSpacing: CGFloat = 8
    
    
    
    var body: some View {        
        DropDownView(verticalOffset: 58, showOptions: $ui.showTimePopup) {
            timeRow
        } dropDown: {
            SelectRespondTime(selectedDay: $selectedDate, showTime: $ui.showTimePopup, dates: event.proposedTimes.availableDates())
        }
    }
}

extension RespondTimeView {
    
    private var dropdownVerticalOffset: CGFloat {
        max(0, rowHeight - topLineBottom - dropdownSpacing)
    }

    
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
        .coordinateSpace(name: "RespondTimeRow")
        .onPreferenceChange(RespondTimeTopLineBottomKey.self) { topLineBottom = $0 }
    }
    
    private func availableDateWithMessage(message: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(EventFormatting.fullDateAndTime(date))
                    .font(.body(16, .medium))
                    .measure(key: RespondTimeTopLineBottomKey.self) {
                        $0.frame(in: .named("RespondTimeRow")).maxY
                    }
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


private struct RespondTimeTopLineBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
