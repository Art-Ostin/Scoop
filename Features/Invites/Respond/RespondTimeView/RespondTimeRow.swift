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
    @Binding var showMessageScreen: Bool
    
    var showAddMessageButton: Bool {
        vm.respondDraft.newTime.message?.isEmpty != false
    }

    var showOriginal: Bool {
        vm.respondDraft.respondType == .original
    }
    
    var body: some View {
        DropDownView(verticalOffset: 48, showDropDownShadow: true, showOptions: $showTimePopup) {
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
            .opacity(showTimePopup ? 0.02 : 1)
    }
    
    @ViewBuilder
    private var originalTimeRow: some View {
        if let date = vm.respondDraft.selectedDate {
            let message = vm.respondDraft.event.message
            let hasMessage = !(message?.isEmpty ?? true)
            
            VStack(alignment: .leading, spacing: 4) {
                selectedTime(date: date)
                Text(hasMessage ? message! : FormatEvent.hourTime(date))
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .opacity(hasMessage && showTimePopup ? 0.05 : 1)
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
        let showName: Bool = vm.respondDraft.respondType == .modified && vm.respondDraft.newTime.message != nil
        
        VStack(alignment: .leading, spacing: 6) {
            ProposedTimesRow(dates: dates, showTimePopup: $showTimePopup)
            if let message = vm.respondDraft.newTime.event.message {
                messageSection(showName: showName, message: message)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func messageSection(showName: Bool, message: String) -> some View {
        Text("\(showName ? "\(vm.respondDraft.newTime.event.otherUserName) - " : "")\(message)")
            .respondTextFormat(showTimePopup: $showTimePopup.wrappedValue)
            .overlay(alignment: .bottomTrailing) {
                if showAddMessageButton {
                    OpenMessageButton(isEdit: false, showTimePopup: $showTimePopup)
                }
            }
    }
}
