//
//  SelectTimeView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/08/2025.
//

import SwiftUI

struct SelectTimeView: View {

    @Binding var proposedTimes: ProposedTimes
    var isRespondMode = false

    @Environment(\.timeCustomMenuDismiss) private var dismissMenu
    @State private var selectedHour = 22
    @State private var selectedMinute = 30
    @State private var warning: DayWarning?
    @State private var showSaved = false
    @State private var savedTask: Task<Void, Never>?

    @State private var suppressSavedFlash = false
    @State private var displayedCount = 0
    @State private var displayedDates: [ProposedTime] = []

    private let columns = Array(repeating: GridItem(.fixed(27), spacing: 14), count: 7)
    private let dayCount = 11
    private let cellWidth: CGFloat = 30

    // Selected-times list: 2 cells across, then wrap → [date1] [date2] / [date3]
//    private let selectedColumns = Array(
//        repeating: GridItem(.fixed(50), spacing: 24, alignment: .trailing),
//        count: 2
//    )
//    
    @Namespace private var countNS

    var body: some View {
        VStack(spacing: 18) {
            titleSection
            dayPicker
            timePicker
                .padding(.top, -8)
        }
        .modifier(SelectTimeBackground(isRespond: isRespondMode))
        .overlay(alignment: .bottomTrailing) { doneButton }
        .onAppear {
            loadSelectedHourAndMinute()
            displayedCount = proposedTimes.dates.count
            displayedDates = proposedTimes.dates
        }
        .onChange(of: selectedHour * 60 + selectedMinute) {
            proposedTimes.updateTime(hour: selectedHour, minute: selectedMinute)
            if suppressSavedFlash { suppressSavedFlash = false }
            else { flashSaved() }
        }
        .onChange(of: proposedTimes.dates) { old, new in
            // The mutation in selectDay disables animations; re-introduce them here
            // (like displayedCount) so the selectedTimes list can blur in/out.
            if old.count != new.count {
                withAnimation(.snappy(duration: 0.32, extraBounce: 0)) {
                    displayedCount = new.count
                    displayedDates = new
                }
            } else {
                displayedDates = new   // time edit: same count, keep mirror in sync silently
            }
        }
        .task(id: warning) { await clickedUnavailableDay() }
        .animation(.easeInOut(duration: 0.2), value: warning)
        .overlay(alignment: .bottomLeading) { selectedTimes}
    }

    private enum DayWarning: String { case maxReached = "Max 3", dayUnavailable = "Day Unavailable" }
}

//Title Logic and Done Button
private extension SelectTimeView {
    
    private var titleSection: some View {
        HStack {
            Text("Propose 1-3 days to meet") //"Propose up to 3 days"
                .font(.body(17, .medium))
                .foregroundStyle(Color(white: 0.1))
            Spacer()
            timeCountAndWarningSign
        }
    }
    
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
                            .foregroundStyle(Color(white: 0.25))
                            .font(.body(12, .bold))
                            .matchedGeometryEffect(id: "icon", in: countNS, properties: .position)
                            .transition(.opacity)
                    }
                }
                .fixedSize()
            }
    }
    
    private var doneButton: some View {
        Button {
            dismissMenu()
        } label: {
            Image("TickButton")
                .scaleEffect(0.9)
                .frame(width: 33, height: 33)
                .circleStroke(lineWidth: 1, color: .black)
        }
        .shrinkButton(shadow: nil, shadowColor: .clear)
        .padding(.bottom, 96)
        .padding(.horizontal, 24)
    }
}


// Day Picker And Title
private extension SelectTimeView {
    
    var dayPicker: some View {
        VStack(spacing: 10) {                                          // (3) weekday header → numbers
            LazyVGrid(columns: columns, spacing: 0) { dayOfWeekText }  // SAME columns → centers always align
            LazyVGrid(columns: columns, spacing: 10) { daysOfMonthText } // (4) row → row
        }
    }
    
    var dayOfWeekText: some View {
        ForEach(0..<7) { idx in
            Text(
                availableDays[idx]
                    .formatted(.dateTime.weekday(.narrow))       // 3-letter "MON"
                    .uppercased()
            )
            .font(.system(size: 11, weight: .regular))          // Apple SF Pro
            .foregroundStyle(Color(white: 0.75))
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
    
    
    private var selectedTimes: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(displayedDates, id: \.self) { proposedTime in
                Text(FormatEvent.shortDayAndTime(proposedTime.date, withHour: false))
                    .font(.body(10, .bold))
                    .foregroundStyle(Color(red: 0.77, green: 0.77, blue: 0.83))
                    .transition(.blurReplace)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Actions
private extension SelectTimeView {

    func selectDay(day: Date) -> Bool {
        var t = Transaction()
        t.disablesAnimations = true

        // Only the count/day swap is animation-free; the warning is set outside the
        // transaction so the body's .animation(value: warning) still fades it in.
        let hitMax = withTransaction(t) {
            proposedTimes.updateDate(day: day, hour: selectedHour, minute: selectedMinute)
        }
        if hitMax { warning = .maxReached }
        return hitMax
    }

    func clickedUnavailableDay() async {
        guard warning != nil else { return }
        try? await Task.sleep(for: .seconds(1))
        withAnimation(.easeInOut(duration: 0.2)) { warning = nil }
    }

    func flashSaved() {
        savedTask?.cancel()
        savedTask = Task {
            if showSaved {
                withAnimation(.easeInOut(duration: 0.15)) { showSaved = false }
                try? await Task.sleep(for: .milliseconds(120))
                if Task.isCancelled { return }
            }
            withAnimation(.easeInOut(duration: 0.2)) { showSaved = true }
            try? await Task.sleep(for: .milliseconds(1000))
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.2)) { showSaved = false }
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
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 0) //Low bottom as scroll view on Bottom
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
                .foregroundStyle(isSelected ? .white : isToday ? Color(red: 0.06, green: 0.47, blue: 0.94) : Color(white: 0.1))
                .frame(width: 36, height: 36, alignment: .center)                       // bigger circle for 20pt number
                .background {
                    Circle()
                        .fill(isSelected ? Color.accent : Color.clear)
                        .padding(isSelected ? 3 : 0)        // ← inset shrinks the circle when selected
                }
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .frame(width: 27, alignment: .center)
        .showShakeAnimation(bool: shake)
    }
}



/*
 private var titleSection: some View {
     
     VStack(alignment: .leading, spacing: 4) {
         HStack {
             Text("Choose Time")
                 .font(.body(17, .bold))
                 .foregroundStyle(Color(white: 0.1))
             Spacer()
             timeCountAndWarningSign
         }
         
         Text("Propose up to 3 days to Meet")
             .font(.body(12, .regular))
             .foregroundStyle(Color(white: 0.6))
     }
 }
 
 @ViewBuilder
 var dayUnavailablePopup: some View {
     if let warning {
         Text(warning.rawValue)
             .font(.body(12, .bold))
             .foregroundStyle(Color.warningYellow)
             .padding(.horizontal).background(Color.appCanvas).padding(.top, 98)
     }
 }


 */
