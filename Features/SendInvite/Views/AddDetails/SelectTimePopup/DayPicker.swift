//
//  DayPicker.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct DayPicker: View {
    //Injected
    @Binding var proposedTimes: ProposedTimes
    @Binding var dayWarning: DayWarning?
    
    //Injected for the updateTime
    let selectedHour: Int
    let selectedMinute: Int

    //Local Parameters
    let columns = Array(repeating: GridItem(.fixed(28), spacing: 14), count: 7)
    let dayCount = 11
    
    var body: some View {
        VStack(spacing: Spacing.xxs) {
            
            LazyVGrid(columns: columns, spacing: 0) {
                dayOfWeekText
            }
            
            LazyVGrid(columns: columns, spacing: Spacing.xxs) {
                daysOfMonthText
            }
        }
        .padding(.horizontal, -Spacing.xxs)
    }
}

extension DayPicker {
    
    var daysOfMonthText: some View {
        ForEach(availableDays.indices, id: \.self) { idx in
            let day = availableDays[idx]
            DayCell(day: day, isSelected: proposedTimes.contains(day: day)) {
                selectDay(day: day)
            }
        }
    }
    
    var dayOfWeekText: some View {
        ForEach(0..<7) { idx in
            Text(
                availableDays[idx]
                    .formatted(.dateTime.weekday(.narrow))
                    .uppercased()
            )
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(Color.textPlaceholder)
            .fixedSize()// natural width, centered on its column → overflows the 27pt track symmetrically
        }
    }
}

//Functions
extension DayPicker {

    var availableDays: [Date] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfToday)
        }
    }
    
    func selectDay(day: Date) -> Bool {
        let hitMax = proposedTimes.updateDate(day: day, hour: selectedHour, minute: selectedMinute)
        if hitMax { dayWarning = .maxReached }
        return hitMax
    }
}

struct DayCell: View {
    @State private var shake = false
    
    let day: Date
    let isSelected: Bool
    
    let onTap: () -> Bool
    
    var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }
    var body: some View {
        Button {
            if onTap() { shake.toggle() } //Returns bool, if true, triggers shake
        } label: {
            Text(day, format: .dateTime.day())
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))  // Apple SF Pro
                .foregroundStyle(isSelected ? .white : isToday ? Color.accent : Color.textPrimary)
                .frame(width: 36, height: 36, alignment: .center)                       // bigger circle for 20pt number
                .background {
                    Circle()
                        .fill(isSelected ? Color.blackFill : Color.clear)
                        .padding(isSelected ? 3 : 0)        // ← inset shrinks the circle when selected
                }
        }
        .frame(width: 28, alignment: .center)
        .showShakeAnimation(bool: shake)
    }
}
