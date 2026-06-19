//
//  SelectTimeView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/08/2025.
//

import SwiftUI

struct SelectTimeView: View {

    // MARK: Inputs
    @Binding var proposedTimes: ProposedTimes
    var isRespondMode = false

    // MARK: Internal state
    @Environment(\.customMenuDismiss) private var dismissMenu
    @State private var selectedHour = 22
    @State private var selectedMinute = 30
    @State private var warning: DayWarning?

    // MARK: Constants
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayCount = 11

    var body: some View {
        VStack(spacing: 12) {
            dayPicker
            Divider()
            timePicker
        }
        .modifier(SelectTimeBackground(isRespond: isRespondMode))
        .overlay(alignment: .bottomTrailing) { doneButton }
        .overlay(alignment: .top) { dayUnavailablePopup }
        .onAppear { loadSelectedHourAndMinute() }
        .onChange(of: selectedHour * 60 + selectedMinute) {
            proposedTimes.updateTime(hour: selectedHour, minute: selectedMinute)
        }
        .task(id: warning) { await clickedUnavailableDay() }
        .animation(.easeInOut(duration: 0.2), value: warning)
    }

    private enum DayWarning: String { case maxReached = "Max 3", dayUnavailable = "Day Unavailable" }
}

// MARK: - Subviews
private extension SelectTimeView {

    var dayPicker: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            dayOfWeekText
            daysOfMonthText
        }
    }

    var dayOfWeekText: some View {
        ForEach(0..<7) { idx in
            Text(availableDays[idx], format: .dateTime.weekday(.abbreviated))
                .font(.body(12, .regular))
                .foregroundStyle(Color(white: 0.6))
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

    var doneButton: some View {
        ZStack {
            Image("TickButton") //"GreenTickMark"
                .scaleEffect(0.9)
            Circle()
                .stroke(Color.black, lineWidth: 1)
                .scaleEffect(0.8)
        }
        .padding(3)                 // hit area / breathing room
        .background(Color.appCanvas)
        .frame(width: 40, height: 40)
        .contentShape(Circle())
        .onTapGesture { dismissMenu() }
        .padding(.bottom, isRespondMode ? 96 : 80)
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
        withAnimation(.easeInOut(duration: 0.2)) { warning = nil }
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
        selectedHour = cal.component(.hour, from: date)
        selectedMinute = cal.component(.minute, from: date)
    }
}

// MARK: - Supporting Types
private struct SelectTimeBackground: ViewModifier {

    let isRespond: Bool

    func body(content: Content) -> some View {
        content
            .frame(width: 265)
            .padding(.horizontal, isRespond ? 0 : 24)
            .padding(.top, isRespond ? 0 : 24)
            .padding(.bottom, isRespond ? -12 : 0)
    }
}

//Own struct to simplify shake logic
private struct DayCell: View {
    @State private var shake = false

    let day: Date
    let isSelected: Bool
    let onTap: () -> Bool

    var body: some View {
        Button {
            if onTap() { shake.toggle() } //Returns bool, if true, triggers shake
        } label: {
            Text(day, format: .dateTime.day())
                .font(.body(18, isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : .black)
                .frame(width: 30, height: 30)
                .background(isSelected ? Color.accent : Color.clear, in: Circle())
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .showShakeAnimation(bool: shake)
    }
}
