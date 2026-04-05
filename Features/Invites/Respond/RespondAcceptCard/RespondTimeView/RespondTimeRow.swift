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
            ProposedTimesRow(dates: vm.respondDraft.newTime.proposedTimes.dates.map(\.date).sorted(), showTimePopup: $showTimePopup, isAccept: true)
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
                    Text("Select a day to meet")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            //3. Then have drop down button to select available times or a newTime
            customDropDownButton
                .fixedSize()
        }
        .font(.body(17, showTimePopup ? .bold : .medium))
        .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
    }
    
    private var customDropDownButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showTimePopup.toggle()
            }
        } label: {
            Image(systemName: "chevron.down")
                .font(.body(15, .bold))
                .rotationEffect(.degrees(showTimePopup ? 180 : 0))
                .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
                .padding(6)
                .background(
                    Circle().foregroundStyle(.white)
                )
                .surfaceShadow(.floating, strength: 0.5)
                .contentShape(Rectangle())
                .padding(14)
        }
        .buttonStyle(.plain)
        .padding(-14)
        .offset(x: 3)
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
