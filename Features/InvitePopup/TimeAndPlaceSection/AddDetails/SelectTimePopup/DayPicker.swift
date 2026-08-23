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
            Text(availableDays[idx].formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.3))
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
    @State private var selectionTick = 0   // bumps once per accepted tap → one selection click each
    
    let day: Date
    let isSelected: Bool
    
    let onTap: () -> Bool
    
    var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }
    var body: some View {
        Button {
            if onTap() { shake.toggle() } else { selectionTick += 1 } //Returns bool: true = max reached → shake, not a click
        } label: {
            Text(day, format: .dateTime.day())
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))  // Apple SF Pro
                .foregroundStyle(isSelected ? .white : isToday ? Color.accent : Color.textPrimary)
                .frame(width: 36, height: 36, alignment: .center)                       // bigger circle for 20pt number
                .background {
                    Circle()
                        .fill(Color.blackFill)
                        .padding(3)                                                     // the 30pt dot
                        .modifier(SelectionDotAppearance(progress: isSelected ? 1 : 0)) // always mounted; grows/fades in place
                }
                .animation(.selectionDot, value: isSelected)
        }
        .buttonStyle(NoPressStyle())                       // the dot is the touch response; a press dim would ride on top of it
        .frame(width: 28, alignment: .center)
        .showShakeAnimation(bool: shake)
        .sensoryFeedback(.selection, trigger: selectionTick)   // the system day strip's light tick
        .sensoryFeedback(.warning, trigger: shake)             // …and the refusal at the day cap
    }
}

/// No press look at all. The system day cell gives no touch feedback — the default style's
/// label dim (and its slow easeOut restore) multiplies straight into the dot's opacity curve.
private struct NoPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label }
}

/// Drives the selection dot from a single animated progress so opacity can carry the measured
/// `p + 0.16·p(1-p)` lead over scale — the system dot holds its ink while it changes size.
private struct SelectionDotAppearance: ViewModifier, Animatable {
    var progress: Double                       // 0 = deselected, 1 = selected
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    func body(content: Content) -> some View {
        content
            .scaleEffect(0.30 + 0.70 * progress)
            .opacity(progress + 0.16 * progress * (1 - progress))
    }
}
