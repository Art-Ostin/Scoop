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
    var isCardInvite: Bool = false

    var message: String {vm.respondDraft.originalInvite.event.message ?? ""}
    var respondMessageEmpty: Bool { trimmedMessage(vm.respondDraft.respondMessage) == nil }
    var hasRespondMessage: Bool { !respondMessageEmpty }
    var hasMessage: Bool { message.isEmpty == false }
    
    var body: some View {
        DropDownView(verticalOffset: 48, showDropDownShadow: true, showOptions: $showTimePopup) {
            timeView
        } dropDown: {
            RespondSelectTime(vm: vm, showTimePopup: $showTimePopup, showCustomTime: vm.respondDraft.respondType != .original, isRespondPopup: true)
        }
    }
}

//Logic with the standardTimeRow
extension RespondTimeRow {
    
    private var timeView: some View {
        HStack(spacing: 22) {
            Image("MiniClockIcon")
                .opacity(showTimePopup ? 0.03 : 1)
            VStack(alignment: .leading, spacing: 0) {
                timeTitle
                if !hasRespondMessage && !isCardInvite {
                    eventMessageSection
                        .opacity(showTimePopup ? 0.03 : 1)
                }
            }
        }
    }
    
    @ViewBuilder
    private var timeTitle: some View {
        if vm.responseType == .modified {
            ProposedTimesRow(dates: vm.respondDraft.newTime.proposedTimes.dates.map(\.date).sorted(), showTimePopup: $showTimePopup, isAccept: true)
        } else {
            selectedTime
        }
    }
    
    private var eventMessageSection: some View {
        Button {
            showMessageScreen.toggle()
        } label: {
            (
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.gray)
                + Text("  Respond")
                    .font(.body(12, .bold))
                    .foregroundStyle(showMessageScreen ? Color.grayPlaceholder : (vm.responseType == .modified ? .accent : .appGreen))
            )
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
        }
    }
        
    private var selectedTime: some View {
        HStack {
            //1. If there is a selectedDate Show that
            Group {
                if let date = vm.respondDraft.originalInvite.selectedDay {
                    Text(FormatEvent.dayAndTime(date, withHour: (!hasMessage && respondMessageEmpty ? false : true)))
                //2. Otherwise prompt user to select a new availableTime
                } else {
                    Text("Select Time")
                        .font(.body(15, .medium))
                        .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            //3. Then have drop down button to select available times or a newTime
            DropDownChevron(showTimePopup: $showTimePopup)
                .fixedSize()
                .offset(x: 3)
        }
        .font(.body(17, showTimePopup ? .bold : .medium))
        .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
    }

    private func trimmedMessage(_ message: String?) -> String? {
        guard let trimmed = message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
