//
//  SelectTimeView2.swift
//  Scoop
//
//  Created by Art Ostin on 02/08/2025.
//

import SwiftUI

struct SelectTimeView: View {

    //Injected
    @Environment(\.timeCustomMenuDismiss) private var dismissMenu
    @Binding var proposedTimes: ProposedTimes
    var isRespondMode = false

    //Local view state
    @State private var selectedHour = 22
    @State private var selectedMinute = 30
    @State private var warning: DayWarning?
    @State private var showSaved = false
    @State private var savedTask: Task<Void, Never>?
    @State private var suppressSavedFlash = false
    @State private var displayedCount = 0
    @Namespace private var countNS

    private let columns = Array(repeating: GridItem(.fixed(28), spacing: 14), count: 7) //Geometry: calendar pitch (cell + gap), sized to the card
    private let dayCount = 11

    var body: some View {
        VStack(spacing: Spacing.sm) {
            titleSection
            dayPicker
                .padding(.top, Spacing.xxs)
            timePicker
                .padding(.top, -Spacing.xs)
        }
        .modifier(SelectTimeBackground(isRespond: isRespondMode))
        .overlay(alignment: .bottomTrailing) { doneButton }
        .onAppear {
            loadSelectedHourAndMinute()
            displayedCount = proposedTimes.dates.count
        }
        .onChange(of: proposedTimes.dates.count) {
            withAnimation(.toggle) {
                displayedCount = proposedTimes.dates.count
            }
        }
        .onChange(of: selectedHour * 60 + selectedMinute) {
            proposedTimes.updateTime(hour: selectedHour, minute: selectedMinute)
            if suppressSavedFlash { suppressSavedFlash = false }
            else { flashSaved() }
        }
        .task(id: warning) { await clickedUnavailableDay() }
        .animation(.transition, value: warning)
    }

    private enum DayWarning: String { case maxReached = "Max 3", dayUnavailable = "Day Unavailable" }
}

//Title Logic and Done Button
private extension SelectTimeView {
    
    private var titleSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose Time") //"Propose up to 3 days"
                    .font(.body(17, .medium))
                    .foregroundStyle(Color.textPrimary)
                Text("Propose 1-3 days to meet")
                    .font(.body(11, .regular))
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer()
        }
        .overlay(alignment: .topTrailing) { timeAndWarningSign }
    }
    
    
    private var timeAndWarningSign: some View {
        ZStack(alignment: .trailing) {
            if showSaved {
                SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: true)
                    .matchedGeometryEffect(id: "icon", in: countNS, properties: .position)
                    .transition(
                        .scale(scale: 0.4)
                        .combined(with: .opacity)
                    )
            } else if let warning {
                warningText(warning: warning)
            } else {
                dayCountDisplay
            }
        }
        .fixedSize()
    }
    
    private func warningText(warning: SelectTimeView.DayWarning) -> some View {
        Text(warning.rawValue)
            .font(.body(12, .bold))
            .foregroundStyle(Color.warningYellow)
            .matchedGeometryEffect(id: "icon", in: countNS, properties: .position)
            .transition(
                .scale(scale: 0.4)
                .combined(with: .opacity)
            )
    }
    
    private var dayCountDisplay: some View {
        Text("\(displayedCount)/\(ProposedTimes.maxCount)")
            .contentTransition(.numericText(value: Double(displayedCount)))
            .foregroundStyle(Color.textPrimary)
            .font(.body(12, .bold))
            .matchedGeometryEffect(id: "icon", in: countNS, properties: .position)
            .transition(
                .scale(scale: 0.4)
                .combined(with: .opacity)
            )
    }
    
    
    private var doneButton: some View {
        Button {
            dismissMenu()
        } label: {
            Image("TickButton")
                .scaleEffect(0.9)
                .frame(width: 30, height: 30)
                .circleStroke(lineWidth: 1, color: .black)
        }
        .shrinkButton()
        .padding(.bottom, Spacing.clearance - 14) //Positions it at top of time view
        .padding(.horizontal, Spacing.margin)
    }
}


// Day Picker And Title
private extension SelectTimeView {
    
    var dayPicker: some View {
        VStack(spacing: Spacing.xxs) {                                          // Geometry: (3) weekday header → numbers
            LazyVGrid(columns: columns, spacing: 0) { dayOfWeekText }  // SAME columns → centers always align
            LazyVGrid(columns: columns, spacing: Spacing.xxs) { daysOfMonthText } // Geometry: (4) row → row
        }
        .padding(.horizontal, -Spacing.xxs)
    }
    
    var dayOfWeekText: some View {
        ForEach(0..<7) { idx in
            Text(
                availableDays[idx]
                    .formatted(.dateTime.weekday(.narrow))       // 3-letter "MON"
                    .uppercased()
            )
            .font(.system(size: 11, weight: .regular))          // Apple SF Pro
            .foregroundStyle(Color.textPlaceholder)
            .fixedSize()                                         // natural width, centered on its column → overflows the 27pt track symmetrically
        }
    }
    
    var daysOfMonthText: some View {
        ForEach(availableDays.indices, id: \.self) { idx in
            let day = availableDays[idx]
            DayCell(day: day, isSelected: proposedTimes.contains(day: day)) {
                selectDay(day: day)
            }
        }
    }
    
}

//Hour Picker and Days Selected
private extension SelectTimeView {
    
    var timePicker: some View {
        HStack {
            Picker("Hour", selection: $selectedHour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }

            Picker("Minute", selection: $selectedMinute) {
                ForEach([00, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 160, height: 130)
        .labelsHidden()
        .tint(.accent)
        .frame(maxWidth: .infinity)
    }
    
    
}

// MARK: - Actions
private extension SelectTimeView {

    func selectDay(day: Date) -> Bool {
        let hitMax = proposedTimes.updateDate(day: day, hour: selectedHour, minute: selectedMinute)
        if hitMax { warning = .maxReached }
        return hitMax
    }

    func clickedUnavailableDay() async {
        guard warning != nil else { return }
        try? await Task.sleep(for: .seconds(1))
        withAnimation(.transition) { warning = nil }
    }

    func flashSaved() {
        savedTask?.cancel()
        savedTask = Task {
            if showSaved {
                withAnimation(.quick) { showSaved = false }
                try? await Task.sleep(for: .milliseconds(120))
                if Task.isCancelled { return }
            }
            withAnimation(.toggle) { showSaved = true }
            try? await Task.sleep(for: .milliseconds(1000))
            if Task.isCancelled { return }
            withAnimation(.toggle) { showSaved = false }
        }
    }
}

// MARK: - Helpers
private extension SelectTimeView {

    var availableDays: [Date] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfToday)
        }
    }

    func loadSelectedHourAndMinute() {
        guard let date = proposedTimes.dates.first?.date else { return }
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        // If this load moves the wheel, suppress the resulting flash (it's not a
        // user edit). If it lands on the same time, no change fires, nothing to do.
        if h != selectedHour || m != selectedMinute { suppressSavedFlash = true }
        selectedHour = h
        selectedMinute = m
    }
}

private struct SelectTimeBackground: ViewModifier {

    let isRespond: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.margin)
            .padding(.top, Spacing.md)
            .padding(.bottom, -Spacing.xs) //Low bottom as scroll view on Bottom
    }
}

//Own struct to simplify shake logic
private struct DayCell: View {
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
                        .fill(isSelected ? Color.accent : Color.clear)
                        .padding(isSelected ? 3 : 0)        // ← inset shrinks the circle when selected
                }
        }
        .frame(width: 28, alignment: .center)
        .showShakeAnimation(bool: shake)
    }
}

/*
 
 
 private var timeCountAndWarningSign: some View {
     Text("0/3")
         .font(.body(12, .bold))
         .hidden()
         .overlay(alignment: .trailing) {
             ZStack(alignment: .trailing) {
                 if showSaved {
                     SavedIcon(topPadding: 0, horizontalPadding: 0, isSettings: true)
                         .matchedGeometryEffect(id: "icon", in: countNS, properties: .position)
                         .transition(.opacity)
                 } else if let warning {
                     Text(warning.rawValue)
                         .font(.body(12, .bold))
                         .foregroundStyle(Color.warningYellow)
                         .matchedGeometryEffect(id: "icon", in: countNS, properties: .position)
                         .transition(.opacity)
                 } else {
                     Text("\(displayedCount)/3")
                         .contentTransition(.numericText(value: Double(displayedCount)))
                         .foregroundStyle(Color.textPrimary)
                         .font(.body(12, .bold))
                         .matchedGeometryEffect(id: "icon", in: countNS, properties: .position)
                         .transition(.opacity)
                 }
             }
             .fixedSize()
         }
 }
 */
