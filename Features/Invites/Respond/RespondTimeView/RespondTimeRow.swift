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
    
    var showOriginal: Bool {
        vm.respondDraft.respondType == .original
    }
    
    var body: some View {
        DropDownView(verticalOffset: 48, showOptions: $showTimePopup) {
            HStack(spacing: 24) {
                imageIcon
                if showOriginal {originalTimeRow} else {customTimeRow}
            }
        } dropDown: {
            RespondSelectTime(vm: vm, showTimePopup: $showTimePopup)
        }
    }
}

//Logic with the standardTimeRow
extension RespondTimeRow {
    
    private var imageIcon: some View {
        Image("MiniClockIcon")
            .scaleEffect(1.3)
            .opacity(showTimePopup ? 0.05 : 1)
    }
    
    @ViewBuilder
    private var originalTimeRow: some View {
        if let date = vm.respondDraft.selectedDate {
            let message = vm.respondDraft.event.message
            let hasMessage = !(message?.isEmpty ?? true)
            
            VStack(alignment: .leading, spacing: 4) {
                selectedTime(date: date)
                Text(hasMessage ? message! : hour)
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .opacity(hasMessage && showTimePopup ? 0.1 : 1)
                    .lineLimit(hasMessage ? 4 : nil)
            }
        }
    }
    
    private func selectedTime(date: Date) -> some View {
        HStack {
            Text(FormatEvent.dayAndTime(date))
                .font(.body(16, showTimePopup ? .bold : .medium))
            Spacer()
            DropDownButton(isExpanded: $showTimePopup, isAccept: true, showGlass: true)
        }
    }
}

//Logic with CustomTimeRow
extension RespondTimeRow {
    
    @ViewBuilder
    private var customTimeRow: some View {
        let dates = vm.respondDraft.newTime.proposedTimes.dates.map(\.date).sorted()
        VStack(alignment: .leading, spacing: 6) {
    
            ProposedTimesRow(dates: dates, showTimePopup: $showTimePopup)
            
            if let message = vm.respondDraft.event.message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .opacity(showTimePopup ? 0.1 : 1)
                    .lineLimit(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    private var hour: String {
        guard let date = vm.respondDraft.newTime.proposedTimes.dates.compactMap({ $0.date }).first else {return ""}
        return FormatEvent.hourTime(date)
    }
}
