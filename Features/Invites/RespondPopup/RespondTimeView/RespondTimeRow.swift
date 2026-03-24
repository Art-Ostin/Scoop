//
//  RespondTimeView.swift
//  Scoop
//
//  Created by Art Ostin on 22/03/2026.
//

import SwiftUI

struct RespondTimeRow: View {
    
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
            
            if let date = vm.respondDraft.selectedDate {
                if let message = vm.respondDraft.event.message {
                    availableDateWithMessage(message: message, date: date)
                } else {
                    availableDateNoMessage(date: date)
                }
            }
        }
    }
    
    private func availableDateWithMessage(message: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(EventFormatting.fullDateAndTime(date))
                    .font(.body(16, .medium))
                Spacer()
                DropDownButton(isExpanded: $showTimePopup, isAccept: true)
            }
            Text(message)
                .font(.footnote)
                .foregroundStyle(.gray)
                .opacity(showTimePopup ? 0.3 : 1)
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
