//
//  SelectTimeView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/08/2025.
//

import SwiftUI

enum DayWarning: String { case maxReached = "Max 3", dayUnavailable = "Day Unavailable" }

struct SelectTimeView: View {
    
    @Environment(\.customMenuDismiss) private var dismissMenu

    
    @State private var warning: DayWarning?
    
    
    //Updating a proposedTime
    @Binding var proposedTimes: ProposedTimes
    let type: Event.EventType
    @State private var selectedHour = 22
    @State private var selectedMinute = 30
    @State private var didSeed = false

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayCount = 11
    var isRespondMode: Bool = false
    var isRespondPopup: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            dayPicker
                .scaleEffect(isRespondMode ? 0.95 : 1)
            Divider()
                .padding(.horizontal, isRespondMode ? 16 : 0)
            timePicker
                .scaleEffect(isRespondMode ? 0.95 : 1)
                .offset(y: isRespondMode ? -10 : 0)
        }
        //1. The Card Background and overlays
        .modifier(SelectTimeBackground(isRespond: isRespondMode))
        .overlay(alignment: .bottomTrailing) {doneButton}
        .overlay(alignment: .top) {infoSection}

        //Updating time
        .task(id: selectedHour * 60 + selectedMinute) { syncTime() }
        .task(id: warning) {await clickedUnavailableDay()}
        
        //Animations
        .animation(.easeInOut(duration: 0.2), value: warning)
    }
}

//1. The select Time View
extension SelectTimeView {
    
    private var dayPicker: some View {
        return LazyVGrid(columns: columns, spacing: 10) {
            dayOfWeekText
            
            ForEach(availableDays.indices, id: \.self) { idx in
                let day = availableDays[idx]
                DayCell(day: day, isSelected: proposedTimes.contains(day: day)) {
                    selectDay(day: day)
                }
            }
        }
    }
    
    private var dayOfWeekText: some View {
        ForEach(0..<7) {idx in
            Text(availableDays[idx], format: .dateTime.weekday(.abbreviated))
                .font(.body(12, .regular))
                .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
        }
    }
    
    private func selectDay(day: Date) -> Bool {
        let hitMax = proposedTimes.updateDate(day: day, hour: selectedHour, minute: selectedMinute)
        if hitMax { warning = .maxReached }
        return hitMax
    }
}

private struct DayCell: View {
    let day: Date
    let isSelected: Bool
    let onTap: () -> Bool

    @State private var shake = false

    var body: some View {
        Button {
            if onTap() { shake.toggle() }
        } label: {
            Text(day, format: .dateTime.day())
                .font(.body(18, isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .accent : .black)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .offset(y: -1)
                        .strokeBorder(.black, lineWidth: isSelected ? 1 : 0)
                        .transaction { $0.animation = .linear(duration: 0.03) }
                )
                .contentShape(.rect)
        }
        .showShakeAnimation(bool: shake)
    }
}

//2. Key Compoenents
extension SelectTimeView {
    
    @ViewBuilder
    private var infoSection: some View {
        if let warning {
            Text(warning.rawValue)
                .font(.body(12, .bold))
                .foregroundStyle(Color.warningYellow)
                .padding(.horizontal).background(Color.appCanvas).padding(.top, 98)
        }
    }
        
    private var availableDays: [Date] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfToday)
        }
    }
    
    private var timePicker: some View {
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
    
    private var doneButton: some View {
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
            .onTapGesture {
                dismissMenu()
            }
            .padding(.bottom, isRespondMode ? 96 : 80)
    }
}

//Functions needed
extension SelectTimeView {
    
    private var firstHM: (hour: Int, minute: Int)? {
        guard let date = proposedTimes.dates.first?.date else { return nil }
        let cal = Calendar.current
        return (cal.component(.hour, from: date), cal.component(.minute, from: date))
    }

    private func syncTime() {
        guard didSeed else {
            didSeed = true
            if let hm = firstHM { (selectedHour, selectedMinute) = hm }
            return
        }
        proposedTimes.updateTime(hour: selectedHour, minute: selectedMinute)
    }

    private func clickedUnavailableDay() async {
        guard warning != nil else { return }
            try? await Task.sleep(for: .seconds(1))
            withAnimation(.easeInOut(duration: 0.2)) { warning = nil }
    }
}

private struct SelectTimeBackground: ViewModifier {
    
    let isRespond: Bool
    
    func body(content: Content) -> some View {
        content
            .frame(width: (isRespond && !isRespond) ? 270 : 265)
            .padding(.horizontal, isRespond ? 0 : 24)
            .padding(.top, isRespond ? 0 : 24)
            .padding(.bottom, isRespond ? -12 : 0)
    }
}
