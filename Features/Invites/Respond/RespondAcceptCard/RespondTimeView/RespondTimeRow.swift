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
    
    private var imageIcon: some View {
        Image("MiniClockIcon")
            .scaleEffect(1.3)
            .opacity(showTimePopup ? 0.02 : 1)
            .offset(y: showMessageResponse ? 4 : 0)
    }
    
    private var timeView: some View {
        HStack(spacing: 24) {
            imageIcon
            VStack {
                timeTitle
                timeSubHeader(text: <#T##String#>)
            }
        }
    }
    
    @ViewBuilder
    private var timeTitle: some View {
        if vm.responseType == .original {
            selectedTime(date: date)
        } else {
            let dates = vm.respondDraft.newTime.proposedTimes.dates.map(\.date).sorted()
            ProposedTimesRow(dates: dates, showTimePopup: $showTimePopup, isAccept: true)
        }
    }

    
    
    
    private func timeSubHeader(text: String) -> some View {
        
        let subHeaderText = vm.respondDraft.event.proposedTimes.firstAvailableDate.
        
        
        Text(text)
            .font(.footnote)
            .foregroundStyle(.grayText)
            .opacity(showTimePopup ? 0.1 : 1)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment:.leading)
    }

    
    
    private func selectedTime(date: Date) -> some View {
        HStack {
            Text(FormatEvent.dayAndTime(date))
                .font(.body(16, showTimePopup ? .bold : .medium))
            Spacer()
            DropDownButton(isExpanded: $showTimePopup, isAccept: true, showGlass: true)
        }
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

