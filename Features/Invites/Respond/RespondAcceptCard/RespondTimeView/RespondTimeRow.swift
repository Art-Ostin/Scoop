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

    var message: String {vm.respondDraft.event.message ?? ""}
    var newMessageEmpty: Bool {vm.respondDraft.newTime.message?.isEmpty != false}
    
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
        HStack(spacing: 24) {
            Image("MiniClockIcon").scaleEffect(1.3)
                .opacity(showTimePopup ? 0.03 : 1)
            VStack {
                timeTitle
                if newMessageEmpty || vm.responseType == .original {
                    timeSubHeader
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

    private var timeSubHeader: some View {
        Group {
            if !message.isEmpty{
                Text(message)
            } else if let date = vm.respondDraft.eventDraft.proposedTimes.firstAvailableDate {
                Text(FormatEvent.hourTime(date))
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
            if newMessageEmpty && vm.responseType == .modified {
                addMessageButton
            }
        }
    }
    
    private var selectedTime: some View {
        HStack {
            //1. If there is a selectedDate Show that
            if let date = vm.respondDraft.selectedDate {
                Text(FormatEvent.dayAndTime(date))
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
    

    private var addMessageButton: some View {
        Button {
            showMessageScreen = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName:"plus")
                    .font(.system(size: 10, weight: .bold))
                
                Text("Add note")
                    .font(.custom("SFProRounded-Bold", size: 11))
                    .kerning(0.4)
            }
            .foregroundStyle(Color.grayText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.92))
            }
            .stroke(24, lineWidth: 1, color: Color.grayBackground)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(.rect)
        }
        .offset(y: 20)
    }
}





/*
 
 //Logic with CustomTimeRow
 extension RespondTimeRow {
     
     @ViewBuilder
     private var customTimeRow: some View {
         let dates = vm.respondDraft.newTime.proposedTimes.dates.map(\.date).sorted()
         VStack(alignment: .leading, spacing: showMessageResponse ? 24 : 6) {
             ProposedTimesRow(dates: dates, showTimePopup: $showTimePopup)
             TimeSubheader(showMessageScreen: $showMessageScreen, showTimePopup: showTimePopup, event: vm.respondDraft.event)
         }
         .frame(maxWidth: .infinity, alignment: .leading)
     }
 }

 
 
 if let date = vm.respondDraft.selectedDate {
     let message = vm.respondDraft.event.message
     let hasMessage = !(message?.isEmpty ?? true)
     
     
     
     
     VStack(alignment: .leading, spacing: 4) {
         
         
         
         selectedTime(date: date)
         Text(hasMessage ? message! : FormatEvent.hourTime(date))
             .font(.footnote)
             .foregroundStyle(.gray)
             .opacity(hasMessage && showTimePopup ? 0.05 : 1)
             .lineLimit(hasMessage ? 4 : nil)
     }
 }
}
 
 
 private func hourView(_ date: Date)  -> some View {
     Text(FormatEvent.hourTime(date))
         .font(.caption)
         .foregroundStyle(Color.grayText)
         .frame(maxWidth: .infinity, alignment: .leading)
 }

 private func singleMessageView(_ message: String) -> some View {
     Text(message)
         .font(.footnote)
         .foregroundStyle(.gray)
         .opacity(showTimePopup ? 0.1 : 1)
         .lineLimit(nil)
         .fixedSize(horizontal: false, vertical: true)
         .layoutPriority(1)
         .multilineTextAlignment(.leading)
         .frame(maxWidth: .infinity, alignment:.leading)

 
     
 
 
 
 
 @ViewBuilder
 private func timeRow(date: Date) -> some View {
     let message = vm.respondDraft.event.message
     let text = message?.isEmpty == false ? message! : FormatEvent.hourTime(date)
     let dates = vm.respondDraft.newTime.proposedTimes.dates.map(\.date).sorted()

     VStack {
         if vm.responseType == .original {
             selectedTime(date: date)
         } else {
             ProposedTimesRow(dates: dates, showTimePopup: $showTimePopup, isAccept: true)
         }
     }
 }

 
     
 */

