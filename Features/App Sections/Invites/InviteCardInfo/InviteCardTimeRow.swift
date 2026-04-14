//
//  InviteCardTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 10/04/2026.
//

import SwiftUI

struct InviteCardTimeRow: View {    
    @Binding var showTimePopup: Bool
    @Bindable var vm: RespondViewModel
        
    var body: some View {
        DropDownView(opensAbove: true, verticalOffset: 0, showOptions: $showTimePopup) {
            timeView
                .anchorPreference(key: InviteCardTimeRowBoundsKey.self, value: .bounds) { $0 }
        } dropDown: {
//            RespondSelectTime(vm: vm, showTimePopup: $showTimePopup)
        }
    }
}

extension InviteCardTimeRow {
    
    private var timeView: some View {
        HStack(spacing: 8) {
            Image("MiniClockIcon")
                .opacity(showTimePopup ? 0.03 : 1)
            timeTitle
        }
    }
    
    @ViewBuilder
    private var timeTitle: some View {
        if vm.responseType == .original {
            selectedTime
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ProposedTimesRow(dates: vm.respondDraft.newTime.proposedTimes.dates.map(\.date).sorted(), showTimePopup: $showTimePopup, isAccept: true)
            }
        }
    }
    
    private var selectedTime: some View {
        HStack {
            //1. If there is a selectedDate Show that
            Group {
                if let date = vm.respondDraft.originalInvite.selectedDay {
                    Text(FormatEvent.dayAndTime(date, withHour:  true))
                    
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
                .offset(x: 4)
        }
        .font(.body(17, showTimePopup ? .bold : .medium))
        .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
    }
}

struct InviteCardTimePopup: View {
    @Binding var showTimePopup: Bool
    @Bindable var vm: RespondViewModel

    var body: some View {
        DropDownView(opensAbove: true, verticalOffset: 36, showOptions: $showTimePopup) {
            Color.clear
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
        } dropDown: {
            RespondSelectTime(vm: vm, showTimePopup: $showTimePopup)
        }
        .allowsHitTesting(showTimePopup)
    }
}

struct InviteCardTimeRowBoundsKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}



/*
 
 //
 //            SelectTimeView(
 //                proposedTimes: $vm.respondDraft.newTime.proposedTimes,
 //                type: vm.respondDraft.originalInvite.event.type,
 //                showTimePopup: $showTimePopup
 //            )

 
 
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

 */

/*
 if let selectedDay {
     DropDownView(opensAbove: true, verticalOffset: 36, showOptions: $showTimePopup) {
         if vm.responseType == .original {
             originalTimeRow(selectedDay: selectedDay)
         } else {
             
             //                        ProposedTimesRow(dates: <#T##[Date]#>, showTimePopup: <#T##Binding<Bool>#>, isAccept: <#T##Bool#>)
         }
     } dropDown: {
         RespondSelectTime(vm: vm, showTimePopup: $showTimePopup)
     }
 } else {
     originalTimeRow(selectedDay: selectedDay)
 }
 */
