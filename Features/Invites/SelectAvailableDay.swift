//
//  SelectAvailableDayView.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct SelectAvailableDay: View {
    
    let event: UserEvent
    
    @Binding var selectedDay: Date?
    @Binding var showTimePopup: Bool
    
    
    var body: some View {
            VStack(spacing: 12) {
                let dates = event.proposedTimes.availableDates()
                
                ForEach(dates.indices, id: \.self) { idx in
                    availableDayRow(idx: idx, dates: dates)
                }
                customDateRow
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.background)
            )
    }
}


extension SelectAvailableDay {
    
    @ViewBuilder
    private func availableDayRow(idx: Int, dates: [Date]) -> some View {
        let date = dates[idx]
        let formattedDate = EventFormatting.fullDateAndTime(date)
        
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                Text("\(idx + 1)")
                Text(formattedDate)
            }
            
            CustomDivider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { selectDay(date: date)}
        .font(.body(17, selectedDay == date ? .bold : .regular))
        
    }
    
    private var customDateRow: some View {
        HStack(spacing: 16) {
            Text("🖊️")
            Text("Propose New date")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .font(.body(17, .regular))
    }
    
    private func selectDay(date: Date) {
        selectedDay = date
        
        withAnimation(.easeInOut(duration: 0.25)) {
            showTimePopup = false
        }
    }
}
