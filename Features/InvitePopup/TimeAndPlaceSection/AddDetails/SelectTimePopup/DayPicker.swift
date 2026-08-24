//
//  DayPicker.swift
//  Scoop
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
    let columns = Array(repeating: GridItem(.fixed(DayCell.track), spacing: DayCell.columnGap), count: 7)
    let dayCount = 11
    
    var body: some View {
        VStack(spacing: Spacing.xxs) {
            
            LazyVGrid(columns: columns, spacing: 0) {
                dayOfWeekText
            }
            
            LazyVGrid(columns: columns, spacing: 0) { //Cells carry the row pitch (see DayCell)
                daysOfMonthText
            }
        }
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
                .font(.body(12, .medium))
                .foregroundStyle(Color.textTertiary)
                .fixedSize() //Natural width, centred on its column → overflows the 28pt track symmetrically
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

    //Geometry: 7 × 28 tracks + 6 × 13 gaps = 274 fits the 277pt content column (325 platter − 2 × 24 margin),
    //so the outer 30pt dots' edges land on the margin — one vertical edge with the title and the tick button.
    static let track: CGFloat = 28
    static let columnGap: CGFloat = 13
    private static let dotFrame: CGFloat = 36 //Geometry: the 30pt dot plus a 3pt ring the grow-in scales within
    private static let dotInset: CGFloat = 3  //Geometry: the measured 30pt system selection dot
    //The cell is the full pitch (41 × 40) so a tap anywhere between two days still lands — cells tile
    //exactly, no dead gaps, no overlap. The grid's own row spacing is 0: the cell carries the row pitch.
    private static let cellSize = CGSize(width: track + columnGap, height: dotFrame + Spacing.xxs)
    
    var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }
    var body: some View {
        Button {
            if onTap() { shake.toggle() } else { selectionTick += 1 } //Returns bool: true = max reached → shake, not a click
        } label: {
            Text(day, format: .dateTime.day())
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))  // Apple SF: the numerals match the SF wheel below
                .foregroundStyle(isSelected ? .white : isToday ? Color.textAccent : Color.textPrimary)
                .frame(width: Self.dotFrame, height: Self.dotFrame, alignment: .center)
                .background {
                    Circle()
                        .fill(Color.blackFill)
                        .padding(Self.dotInset)
                        .modifier(SelectionDotAppearance(progress: isSelected ? 1 : 0)) // always mounted; grows/fades in place
                }
                .animation(.selectionDot, value: isSelected)
                .frame(width: Self.cellSize.width, height: Self.cellSize.height)
                .contentShape(Rectangle())
        }
        .buttonStyle(NoPressStyle())                       // the dot is the touch response; a press dim would ride on top of it
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
