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
        DropDownView(verticalOffset: 58, showOptions: $showTimePopup) {
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
            .opacity(showTimePopup ? 0.3 : 1)
    }
    
    @ViewBuilder
    private var originalTimeRow: some View {
        if let date = vm.respondDraft.selectedDate {
            if let message = vm.respondDraft.event.message {
                availableDateWithMessage(message: message, date: date)
            } else {
                availableDateNoMessage(date: date)
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
}

//Logic with CustomTimeRow
extension RespondTimeRow {
    
    @ViewBuilder
    private var customTimeRow: some View {
        let dates = vm.respondDraft.newTime.proposedTimes.dates.map(\.date).sorted()
        let title = "New Proposed Day" + (vm.respondDraft.newTime.proposedTimes.dates.count > 1 ? "s:" : ":")
        
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .kerning(0.5)
                    .foregroundStyle(Color.accent)
                    .font(.body(10, .bold))
                
                Spacer()
                
                if (vm.respondDraft.event.message != nil) && vm.respondDraft.respondType == .modified {
                    Text(hour)
                        .font(.body(13, .regular))
                        .foregroundStyle(Color.grayText)
                        .padding(.horizontal, 30)
                }
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                Group {
                    if dates.count == 1 {
                        oneDateView(dates: dates)
                    } else {
                        datesText(dates: dates)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)

                DropDownButton(isExpanded: $showTimePopup)
            }
            

            Text(vm.respondDraft.event.message ?? "")
                .font(.footnote)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func datesText(dates: [Date]) -> some View {
        var result = Text("")

        for (index, date) in dates.enumerated() {
            result = result
            + Text(FormatEvent.dayAndTime(date, wide: (dates.count == 3 ? false : true), withHour: false))
            + Text(index == dates.count - 1 ? "" : ",  ")
        }
        return result.frame(maxWidth: .infinity, alignment: .leading).font(.body(16, .medium))
    }

    private func oneDateView(dates: [Date]) ->  some View {
        Text(FormatEvent.dayAndTime(dates.first ?? Date(), withHour: false))
            .font(.body(16, .medium))
    }
    
    private var hour: String {
        guard let date = vm.respondDraft.newTime.proposedTimes.dates.compactMap({ $0.date }).first else {return ""}
        return FormatEvent.hourTime(date)
    }
}

/*
 private var customTimeRow: some View {
     VStack(alignment: .leading, spacing: 4) {
         customTimeView
     }
 }

 */
