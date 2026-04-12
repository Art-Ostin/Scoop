//
//  InviteCardTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 10/04/2026.
//

import SwiftUI

struct InviteCardTimeRow: View {
    
    let selectedDay: Date?
    
    @Binding var showMessageScreen: Bool
    @Binding var showTimePopup: Bool
    @Bindable var vm: RespondViewModel
    
    
    var body: some View {
        if let selectedDay {
            DropDownView(opensAbove: true, verticalOffset: 36, showOptions: $showTimePopup) {
                originalTimeRow(selectedDay: selectedDay)
            } dropDown: {
                SelectTimeView(proposedTimes: $vm.respondDraft.newTime.proposedTimes, type: vm.respondDraft.originalInvite.event.type, showTimePopup: $showTimePopup)
            }
        }
    }
}

extension InviteCardTimeRow {
    private func originalTimeRow(selectedDay: Date) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image("MiniClockIcon")

            VStack(alignment: .leading) {
                Text(FormatEvent.dayAndTime(selectedDay))
                    .font(.body(16, .medium))
                    .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .offset(y: 0.5)
                
//                if vm.respondDraft.respondMessage?.isEmpty ?? true {
//                    if let message = vm.respondDraft.originalInvite.event.message {
//                        eventMessageSection(message: message)
//                    }
//                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            DropDownChevron(showTimePopup: $showTimePopup)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func eventMessageSection(message: String) -> some View {
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
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
