//
//  InviteTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

//Consistent Row heights so 'option' and actual text line up. Not done HStack for each row
//as need the right side of the rows to be one single button
enum RowH {static let smallHour: CGFloat = 13 ; static let singleTime: CGFloat = 17; static let multipleTime: CGFloat = 15 ; static let noTimeHeight: CGFloat = 16}

struct InviteTimeRow: View {

    @Bindable var ui: TimeAndPlaceUIState
    @Binding var showTimePopup: Bool
    @Binding var proposedTimes: ProposedTimes

    //Live edits happen on this draft inside the open menu; the real binding (and
    //therefore this row's label) is only updated when the menu is dismissed.
    @State private var draft = ProposedTimes()

    var times: [Date] {
        proposedTimes.dates.map(\.date)
    }
    
    var hour: String {
        times.first?.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) ?? ""
    }
    
    
    
    var body: some View {
        
        HStack {
            leadingText
            Spacer()
            trailingTextAsMenuLabel
        }
        .transition(.opacity.animation(.smooth(duration: 0.2)))
    }
}

//If less than 2 proposed times
extension InviteTimeRow {
    
    @ViewBuilder
    private var leadingText: some View {
        if times.count <= 1 {
            singleTimeLeadingText
        } else {
            multipleTimeLeadingText
        }
    }
    
    private var singleTimeLeadingText: some View {
        inviteTypeText(.when)
            .frame(height: times.count == 0 ? RowH.noTimeHeight : RowH.singleTime)
    }
    
    
    private var multipleTimeLeadingText: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When")
                .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                .font(.body(12, .bold))
                .frame(height: RowH.smallHour)
            
            
            ForEach(0..<times.count, id: \.self) { idx in
                Text("Option \(idx + 1)")
                    .kerning(0.24)
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                    .font(.body(12, .regular))
                    .frame(height: RowH.multipleTime)
            }
        }
    }
}

//Trailing Text
extension InviteTimeRow  {
    
    private var trailingTextAsMenuLabel: some View {
        TimeCustomMenu(
            onOpen: {
                draft = proposedTimes        // seed the draft from the committed value
                ui.timePopupOpen = true
            },
            onClose: {
                proposedTimes = draft         // commit once, the moment it dismisses
                ui.timePopupOpen = false
            }
        ) {
            SelectTimeView(proposedTimes: $draft)
                .zIndex(2)
        } label: {
            trailingText
        }
    }
    
    private var trailingText: some View {
        HStack(spacing: 12) {
            if times.count <= 1 {
                singleTimeTrailingText
            } else {
                multipleTimeTrailingText
            }
            DropDownButton(isOpen: showTimePopup)
        }
    }
    
    @ViewBuilder
    private var singleTimeTrailingText: some View {
        if times.count == 0 {
            Text("Choose Time")
                .kerning(0.32)
                .font(.body(16, .regular))
                .foregroundStyle(Color(white: 0.4))
                .transition(.opacity.animation(.smooth(duration: 0.2)))
                .frame(height: RowH.noTimeHeight)
        } else if let proposedDay = times.first {
            Text( FormatEvent.dayAndTime(proposedDay, wide: true, withHour: true))
                .font(.body(17, .medium))
                .transition(.opacity.animation(.smooth(duration: 0.2)))
                .frame(height: RowH.singleTime)
        }
    }
    
    private var multipleTimeTrailingText: some View {
        VStack(alignment: .trailing, spacing: 8){
            multipleTimeTrailingHour
            
            ForEach(times.indices, id: \.self) {idx in
                mutlipleTimeTrailingDay(idx)
            }
        }
    }
    
    @ViewBuilder
    private var multipleTimeTrailingHour: some View {
        if let firstDay = times.first {
            Text(FormatEvent.hourTime(firstDay))
                .font(.body(13, .bold))
                .opacity(ui.typePopupOpenDelayed ? 0 : 1) //Hide it when typePopup Open -> Makes bit smoother
                .frame(height: RowH.smallHour)
        }
    }
    
    private func mutlipleTimeTrailingDay(_ idx: Int) ->  some View {
        let day = times[idx]
        
        return Text(FormatEvent.dayAndTime(day, withHour: false))
            .font(.body(15, .regular))
            .opacity(ui.typePopupOpenDelayed ? 0 : 1)
            .frame(height: RowH.singleTime)
    }
    
}


