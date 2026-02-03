//
//  SelectTimeView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/08/2025.
//

import SwiftUI
import Foundation

struct SelectTimeView: View {
    
    @Bindable var vm: TimeAndPlaceViewModel
    
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayCount = 11 //Meet up, up to 10 days in future, not including today
    
    var body: some View {
        DropDownMenu(cornerRadius: 16) {
            VStack(spacing: 12) {
                dayPicker
                Divider()
                timePicker
            }
        }
        .onAppear { syncTimePickerIfNeeded() }
        .onChange(of: vm.selectedHour) {vm.event.proposedTimes.updateTime(hour: vm.selectedHour, minute: vm.selectedMinute) }
        .onChange(of: vm.selectedMinute) {vm.event.proposedTimes.updateTime(hour: vm.selectedHour, minute: vm.selectedMinute) }
        .onChange(of: vm.event.proposedTimes.dates) { syncTimePickerIfNeeded()}
    }
}

//Views
extension SelectTimeView {
    
    private var days: [Date] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfToday)
        }
    }
    
    private var dayPicker: some View {
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<7) {idx in
                Text(days[idx], format: .dateTime.weekday(.narrow))
                    .font(.body(12, .bold))
            }
            ForEach(days.indices, id: \.self) { idx in
                event(idx: idx)
            }
        }
    }

    @ViewBuilder
    private func event(idx: Int) -> some View {
        let day = days[idx]
        let isToday = Calendar.current.isDateInToday(day)
        let isSelected = vm.event.proposedTimes.contains(day: day)
        Button {
            vm.event.proposedTimes.updateDate(day: day, hour: vm.selectedHour, minute: vm.selectedMinute)
        } label : {
            Text(day, format: .dateTime.day())
                .font(.body(18, isSelected ? .bold : .medium))
                .foregroundStyle(isToday ? Color.grayPlaceholder : .black)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .foregroundStyle(isSelected ? Color.accent.opacity(0.2) : Color.clear)
                )
                .contentShape(.rect)
        }
    }
    
    private var timePicker: some View {
        HStack {
            Picker("Hour", selection: $vm.selectedHour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            
            Picker("Minute", selection: $vm.selectedMinute) {
                ForEach([00, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 160, height: 130)
        .labelsHidden()
        .tint(.appRed)
        .accentColor(.appRed)
    }
    
    private func syncTimePickerIfNeeded() {
        guard let first = vm.event.proposedTimes.dates.first else { return }
        let calendar = Calendar.current
        let newHour = calendar.component(.hour, from: first)
        let newMinute = calendar.component(.minute, from: first)
        if newHour != vm.selectedHour || newMinute != vm.selectedMinute {
            vm.selectedHour = newHour
            vm.selectedMinute = newMinute
        }
    }
}
