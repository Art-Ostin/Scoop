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
        HStack(spacing: 23) {
            Image("MiniClockIcon").scaleEffect(1.3)
                .opacity(showTimePopup ? 0.03 : 1)
            VStack(alignment: .leading) {
                timeTitle
                if let date = vm.respondDraft.originalInvite.event.proposedTimes.firstAvailableDate {
                    Text(FormatEvent.hourTime(date))
                        .font(.footnote)
                        .foregroundStyle(Color.grayText)
                        .opacity(showTimePopup ? 0.1 : 1)
                }
            }
        }
    }
    
    @ViewBuilder
    private var timeTitle: some View {
        if vm.responseType == .original {
            selectedTime
        } else {
            ProposedTimesRow(dates: vm.respondDraft.newTime.proposedTimes.dates.map(\.date).sorted(), showTimePopup: $showTimePopup, isAccept: true)
        }
    }

    @ViewBuilder
    private var timeSubHeader: some View {
        Group {
            if let message = vm.respondDraft.originalInvite.event.message {
                Text(message)
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
        .overlay(alignment: .bottomTrailing) {
            if respondMessageEmpty {
                AddMessageButton(showMessageScreen: $showMessageScreen)
            }
        }
    }
        
    private var selectedTime: some View {
        HStack {
            //1. If there is a selectedDate Show that
            if let date = vm.respondDraft.originalInvite.selectedDay {
                Text(FormatEvent.dayAndTime(date, withHour: false))
                    .font(.body(16, showTimePopup ? .bold : .medium))
                
            //2. Otherwise prompt user to select a new availableTime
            } else {
                Text("Select a day to meet")
                    .font(.body(16, showTimePopup ? .bold : .medium))
            }
            
            //3. Then have drop down button to select available times or a newTime
            Spacer()
            DropDownButton(isExpanded: $showTimePopup, isAccept: true, showGlass: true)
        }
    }
}


/*
 HStack(spacing: 2) {
     Text("\(type.description.label)")
         .font(.body(16, .medium))
     Image(systemName: "info.circle")
         .foregroundStyle(Color.grayText).opacity(0.8)
         .font(.body(14, .medium))
         .offset(y: -4)
 }

 */

/*
 if respondMessageEmpty {
     timeSubHeader
 }

 
 //                if let date = vm.respondDraft.originalInvite.event.proposedTimes.firstAvailableDate {
 //                    Text(FormatEvent.hourTime(date))
 //                        .font(.footnote)
 //                        .foregroundStyle(Color.grayText)
 //                        .opacity(showTimePopup ? 0.1 : 1)
 //                }

 
 */
