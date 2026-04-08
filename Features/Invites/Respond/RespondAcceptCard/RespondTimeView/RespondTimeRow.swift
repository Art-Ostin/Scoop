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

    var message: String {vm.respondDraft.originalInvite.event.message ?? ""}
    var respondMessageEmpty: Bool {vm.respondDraft.respondMessage?.isEmpty != false}
    var hasMessage: Bool { message.isEmpty == false }
    
    var body: some View {
        DropDownView(verticalOffset: 48, showDropDownShadow: true, showOptions: $showTimePopup) {
            timeView
        } dropDown: {
            RespondSelectTime(vm: vm, showTimePopup: $showTimePopup)
        }
    }
}

//Logic with the standardTimeRow
extension RespondTimeRow {
    
    private var timeView: some View {
        HStack(spacing: 22) {
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
            VStack(alignment: .leading, spacing: 4) {
                ProposedTimesRow(dates: vm.respondDraft.newTime.proposedTimes.dates.map(\.date).sorted(), showTimePopup: $showTimePopup, isAccept: true)
                if vm.respondDraft.newTime.proposedTimes.dates.count == 3 {
                    if let firstDate = vm.respondDraft.newTime.proposedTimes.dates.first?.date {
                        Text(FormatEvent.hourTime(firstDate))
                            .font(.body(12, .medium))
                            .foregroundStyle(Color(red: 0.72, green: 0.72, blue: 0.72))
                    }
                }
            }
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
                    Text("Select time")
                        .font(.body(15, .italic))
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
}

/*
 
 .background(
     RoundedRectangle(cornerRadius: 24)
         .foregroundStyle(Color.white)
 )
 .surfaceShadow(.floating, strength: 0.7)
 */


/*
 
 @ViewBuilder
 private var timeSubHeader: some View {
     Group {
         if let message = vm.respondDraft.originalInvite.event.message {
             (
                 Text(message)
                 +
                 Text(respondMessageEmpty ? "  Add Response" : "")
                     .font(.body(10, .bold))
                     .foregroundStyle(Color.appGreen)
             )
         } else if let date = vm.respondDraft.originalInvite.event.proposedTimes.firstAvailableDate {
             Text(FormatEvent.hourTime(date))
         } else {
             EmptyView()
         }
     }
     .font(.footnote)
     .foregroundStyle(Color.grayText)
     .opacity(showTimePopup ? 0.1 : 1)
     .lineLimit(nil)
     .fixedSize(horizontal: false, vertical: true)
     .layoutPriority(1)
     .multilineTextAlignment(.leading)
     .frame(maxWidth: .infinity, alignment:.leading)
 }

 
 if respondMessageEmpty {
     timeSubHeader
 }

 */
