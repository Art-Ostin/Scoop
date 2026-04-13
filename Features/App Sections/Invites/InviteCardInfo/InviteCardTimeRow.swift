//
//  InviteCardTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 10/04/2026.
//

import SwiftUI

struct InviteCardTimeRow: View {
    
    let selectedDay: Date?
    
    @Binding var showTimePopup: Bool
    @Bindable var vm: RespondViewModel
    var useDropDown: Bool = true
    
    var body: some View {
        if let selectedDay {
            if useDropDown {
                DropDownView(opensAbove: true, verticalOffset: 36, showOptions: $showTimePopup) {
                    originalTimeRow(selectedDay: selectedDay)
                } dropDown: {
                    SelectTimeView(
                        proposedTimes: $vm.respondDraft.newTime.proposedTimes,
                        type: vm.respondDraft.originalInvite.event.type,
                        showTimePopup: $showTimePopup
                    )
                }
            } else {
                originalTimeRow(selectedDay: selectedDay)
                    .opacity(0)
                    .allowsHitTesting(false)
                    .anchorPreference(key: InviteCardTimeRowBoundsKey.self, value: .bounds) { $0 }
            }
        }
    }
}

extension InviteCardTimeRow {
    private func originalTimeRow(selectedDay: Date) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image("MiniClockIcon")

            VStack(alignment: .leading) {
                Text(FormatEvent.dayAndTime(selectedDay))
                    .font(.body(16, .medium))
                    .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .offset(y: 0.5)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            DropDownChevron(showTimePopup: $showTimePopup)
                .fixedSize()
                .offset(x: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InviteCardTimeRowBoundsKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

