//
//  RespondTimeView.swift
//  Scoop
//
//  Created by Art Ostin on 22/03/2026.
//




import SwiftUI

struct RespondTimeView: View {
    
    @Bindable var ui: ProfileUIState
    @Binding var selectedDate: Date?
    
    let event: UserEvent
    
    var body: some View {        
        DropDownView(showOptions: $ui.showTimePopup) {
            timeRow
        } dropDown: {
            SelectRespondTime(selectedDay: $selectedDate, dates: event.proposedTimes.availableDates())
            .onTapGesture {ui.showTimePopup.toggle()}
        }
    }
}
extension RespondTimeView {
    
    private var timeRow: some View {
        HStack(spacing: 24) {
            Image("MiniClockIcon")
                .scaleEffect(1.3)
            
            if let date = event.proposedTimes.firstAvailableDate {
                if let message = event.message {
                    availableDateWithMessage(message: message, date: date)
                } else {
                    availableDateNoMessage(date: date)
                }
            } else {
                EmptyView()
            }
        }
        
    }
    
    private func availableDateWithMessage(message: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(EventFormatting.fullDateAndTime(date))
                    .font(.body(16, .medium))
                Spacer()
                DropDownButton(isExpanded: $ui.showTimePopup, isAccept: true)
            }
            Text(message)
                .font(.footnote)
                .foregroundStyle(.gray)
        }
    }
    
    private func availableDateNoMessage(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(EventFormatting.fullDate(date, wideMonth: true))
                .font(.body(16, .medium))
            Text(EventFormatting.hourTime(date))
                .font(.footnote)
                .foregroundStyle(.gray)
        }
    }
}



/*
 
 private func getTimeScenario() -> RespondTimeScenario {
     if event.proposedTimes.availableDates().isEmpty {
         return .noAvailableTime
     } else if event.message?.isEmpty == false {
         return .timeWithMessage
     } else {
         return .timeNoMessage
     }

 }
 */

//
/*
 VStack(alignment: .leading, spacing: 4) {
     if let first = event.proposedTimes.firstAvailableDate {
         if let message = event.message {timeRowWithMessage(message:)
             HStack {
                 Text(EventFormatting.fullDateAndTime(first))
                     .font(.body(16, .medium))
                 
                 Spacer()
                 
                 DropDownButton(isExpanded: $ui.showTimePopup, isAccept: true)
             }
             
             Text(message)
                 .font(.footnote)
                 .foregroundStyle(.gray)
         } else {
             Text(EventFormatting.fullDate(first, wideMonth: true))

             Text(EventFormatting.hourTime(first))
                 .font(.footnote)
                 .foregroundStyle(.gray)
         }
     }
 }

 */

/*
 Four Scenarios:
    1. No Time Available
    2. Time available with Message
    3. Time available without message
    4. They have added a time (Deal with this later)
 */
