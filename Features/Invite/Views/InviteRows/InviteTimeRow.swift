//
//  InviteTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI


struct InviteTimeRow: View {

    @Binding var showTimePopup: Bool
    @Binding var proposedTimes: ProposedTimes
    
    let type: Event.EventType
    
    var times: [Date] {
        proposedTimes.dates.map(\.date)
    }
    
    var hour: String {
        times.first?.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) ?? ""
    }
    
    var body: some View {
        
        //Shows two different views if there is more than one time proposed
        Group {
            if times.count <= 1 {
                singleTimeOrLessRow
            } else {
                multipleTimeView
            }
        }
        //1. Adaptive padding based of content
        .padding(.top, timeVerticalTopPadding)
        .padding(.bottom, timeVerticalBottomPadding)
        
    }
}

//If less than 2 proposed times
extension InviteTimeRow {
    
    private var singleTimeOrLessRow: some View {
        HStack {
            inviteTypeText(.when)
            Spacer()
            selectTimeButton
        }
    }
    
    private var selectTimeButton: some View {
        CustomMenu {
            SelectTimeView(proposedTimes: $proposedTimes, type: type, showTimePopup: $showTimePopup)
                .zIndex(2)
        } label: {
            selectTimeLabel
        }
    }
    
    @ViewBuilder
    private var selectTimeLabel: some View {
        HStack(spacing: 12) {
            if let proposedDay = times.first {
               Text( FormatEvent.dayAndTime(proposedDay, wide: true, withHour: true))
                    .font(.body(17, .medium))
            } else {
                Text("Choose Time")
                    .kerning(0.32)
                    .font(.body(16, .regular))
                    .foregroundStyle(Color(white: 0.4))
            }
            Image("InviteChevron")
        }
    }
    
}

extension InviteTimeRow {
    
    private var multipleTimeView: some View {

        // The label spans the full row width (its title row has a Spacer), so the
        // automatic centre-based edge guess misfires — pin it to trailing so the
        // menu lines up on the right like the single-time row.
        CustomMenu(alignment: .trailing) {
            SelectTimeView(proposedTimes: $proposedTimes, type: type, showTimePopup: $showTimePopup)
                .zIndex(2)
        } label: {
            HStack(spacing: 12) {
                VStack(spacing: 4){
                    multipleTimeTitleAndHour
                    ForEach(times.indices, id: \.self) {idx in
                        let time = times[idx]
                        multipleTimeRow(idx: idx, time: time)
                    }
                }
                Image("InviteChevron")
            }
        }
    }
    
    @ViewBuilder
    private var multipleTimeTitleAndHour: some View {
        HStack {
            Text("When")
                .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                .font(.body(12, .bold))
            
            Spacer()
            
            if let firstDay = times.first {
                Text(FormatEvent.hourTime(firstDay))
                    .font(.body(13, .bold))
            }
        }
    }
    
    private func multipleTimeRow(idx: Int, time: Date) -> some View {
        HStack {
            Text("Option \(idx + 1)")
                .kerning(0.24)
                .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                .font(.body(12, .regular))
            Spacer()
            Text(FormatEvent.dayAndTime(time, withHour: false))
                .font(.body(15, .regular))
        }
    }
}






extension InviteTimeRow {
    //Padding adjusted pased of view
    private var timeVerticalTopPadding: CGFloat {
        times.count > 1 ? 14 : 28
    }
    
    private var timeVerticalBottomPadding: CGFloat {
        times.count > 1 ? 12 : 28
    }
}





/*
 
 DropDownView(verticalOffset: 42, showOptions: $showTimePopup) {
     ProposedTimesRow(dates: times, showTimePopup: $showTimePopup, isAccept: false)
         .padding(.vertical, 4)
         .frame(minHeight: 40)
 } dropDown: {
     SelectTimeView(proposedTimes: $proposedTimes, type: type, showTimePopup: $showTimePopup)
         .zIndex(2)
 }

 DropDownView(verticalOffset: 42, showOptions: $showTimePopup) {
     ProposedTimesRow(dates: times, showTimePopup: $showTimePopup, isAccept: false)
         .padding(.vertical, 4)
         .frame(minHeight: 40)
 } dropDown: {
     SelectTimeView(proposedTimes: $proposedTimes, type: type, showTimePopup: $showTimePopup)
         .zIndex(2)
 }
 */
/*
 if times.count > 1 {
     if let firstDate = times.first {
         Text(FormatEvent.hourTime(firstDate))
             .font(.footnote)
             .foregroundStyle(Color.gray)
     }
 }

 */
